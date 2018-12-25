//
//  VideoDecoder.m
//  Athena
//
//  Created by Theresa on 2018/12/24.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <VideoToolbox/VideoToolbox.h>
#import "VideoHardwareDecoder.h"
#import "SharedQueue.h"

@interface VideoHardwareDecoder ()

@property (nonatomic, strong) NSInputStream *inputStream;

@end

const uint8_t lyStartCode[4] = {0, 0, 0, 1};

static void didDecompress(void *decompressionOutputRefCon,
                          void *sourceFrameRefCon,
                          OSStatus status,
                          VTDecodeInfoFlags infoFlags,
                          CVImageBufferRef pixelBuffer,
                          CMTime presentationTimeStamp,
                          CMTime presentationDuration ) {
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

@implementation VideoHardwareDecoder {
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
    
    uint8_t* packetBuffer;
    long packetSize;
    uint8_t* inputBuffer;
    long inputSize;
    long inputMaxSize;
}

- (void)dealloc {
    [self clearH264Deocder];
}

#pragma mark - public

- (instancetype)initWithStream:(NSInputStream *)stream {
    if (self = [super init]) {
        inputSize = 0;
        inputMaxSize = 640 * 480 * 3 * 4;
        inputBuffer = malloc(inputMaxSize);
        _inputStream = stream;
    }
    return self;
}

- (void)startDecode {
    dispatch_async([SharedQueue videoDecode], ^{
        [self.inputStream open];
    });
}

- (void)stopDecode {
    dispatch_async([SharedQueue videoDecode], ^{
        [self cancelStream];
    });
}

- (void)decodeFrame {
    dispatch_async([SharedQueue videoDecode], ^{
        [self readPacket];
        if(packetBuffer == NULL || packetSize == 0) {
            [self cancelStream];
            return;
        }
        uint32_t nalSize = (uint32_t)(packetSize - 4);
        uint32_t *pNalSize = (uint32_t *)packetBuffer;
        *pNalSize = CFSwapInt32HostToBig(nalSize);
        CVPixelBufferRef pixelBuffer = NULL;
        int nalType = packetBuffer[4] & 0x1F;
        switch (nalType) {
            case 0x05:
                NSLog(@"Nal type is IDR frame");
                if([self initH264Decoder]) {
                    pixelBuffer = [self decode];
                }
                break;
            case 0x07:
                NSLog(@"Nal type is SPS");
                _spsSize = packetSize - 4;
                _sps = malloc(_spsSize);
                memcpy(_sps, packetBuffer + 4, _spsSize);
                break;
            case 0x08:
                NSLog(@"Nal type is PPS");
                _ppsSize = packetSize - 4;
                _pps = malloc(_ppsSize);
                memcpy(_pps, packetBuffer + 4, _ppsSize);
                break;
            default:
                NSLog(@"Nal type is B/P frame");
                pixelBuffer = [self decode];
                break;
        }
        if(pixelBuffer) {
            [self.delegate fetch:pixelBuffer];
            CVPixelBufferRelease(pixelBuffer);
        }
        NSLog(@"Read Nalu size %ld", packetSize);
    });
}

#pragma mark - privacy

- (void)cancelStream {
    [self.inputStream close];
    self.inputStream = nil;
    if (inputBuffer) {
        free(inputBuffer);
        inputBuffer = NULL;
    }
}

- (void)clearH264Deocder {
    if(_deocderSession) {
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
    if(_decoderFormatDescription) {
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
    free(_sps);
    free(_pps);
    _spsSize = _ppsSize = 0;
}

- (void)readPacket {
    if (packetSize && packetBuffer) {
        packetSize = 0;
        free(packetBuffer);
        packetBuffer = NULL;
    }
    if (inputSize < inputMaxSize && self.inputStream.hasBytesAvailable) {
        inputSize += [self.inputStream read:inputBuffer + inputSize maxLength:inputMaxSize - inputSize];
    }
    if (memcmp(inputBuffer, lyStartCode, 4) == 0) {
        if (inputSize > 4) { // 除了开始码还有内容
            uint8_t *pStart = inputBuffer + 4;
            uint8_t *pEnd = inputBuffer + inputSize;
            while (pStart != pEnd) { //这里使用一种简略的方式来获取这一帧的长度：通过查找下一个0x00000001来确定。
                if(memcmp(pStart - 3, lyStartCode, 4) == 0) {
                    packetSize = pStart - inputBuffer - 3;
                    if (packetBuffer) {
                        free(packetBuffer);
                        packetBuffer = NULL;
                    }
                    packetBuffer = malloc(packetSize);
                    memcpy(packetBuffer, inputBuffer, packetSize); //复制packet内容到新的缓冲区
                    memmove(inputBuffer, inputBuffer + packetSize, inputSize - packetSize); //把缓冲区前移
                    inputSize -= packetSize;
                    break;
                } else {
                    ++pStart;
                }
            }
        }
    }
}

- (BOOL)initH264Decoder {
    if(_deocderSession) {
        return YES;
    }
    const uint8_t* const parameterSetPointers[2] = { _sps, _pps };
    const size_t parameterSetSizes[2] = { _spsSize, _ppsSize };
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, parameterSetPointers,
                                                                          parameterSetSizes, 4,  &_decoderFormatDescription);
    if(status == noErr) {
        CFDictionaryRef attrs = NULL;
        const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
        uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
        attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = NULL;
        
        status = VTDecompressionSessionCreate(kCFAllocatorDefault, _decoderFormatDescription, NULL,
                                              attrs, &callBackRecord, &_deocderSession);
        CFRelease(attrs);
    } else {
        NSLog(@"IOS8VT: reset decoder session failed status=%d", status);
        return NO;
    }
    return YES;
}

- (CVPixelBufferRef)decode {
    CVPixelBufferRef outputPixelBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, (void*)packetBuffer, packetSize, kCFAllocatorNull,
                                                          NULL, 0, packetSize, 0, &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {packetSize};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault, blockBuffer, _decoderFormatDescription,
                                           1, 0, NULL, 1, sampleSizeArray, &sampleBuffer);
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession, sampleBuffer, flags, &outputPixelBuffer, &flagOut);
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT: Invalid session, reset decoder session");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT: decode failed status=%d(Bad data)", decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS8VT: decode failed status=%d", decodeStatus);
            }
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    return outputPixelBuffer;
}

@end
