//
//  AACEncoder.m
//  Athena
//
//  Created by Theresa on 2017/9/30.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "AACHardEncoder.h"

@interface AACHardEncoder () {
    AudioConverterRef  audioConverter;
    uint8_t           *aacBuffer;
    NSUInteger        aacBufferSize;
    char              *pcmBuffer;
    size_t            pcmBufferSize;
}

@property (nonatomic, strong) dispatch_queue_t encoderQueue;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;

@end

@implementation AACHardEncoder

- (void)dealloc {
    AudioConverterDispose(audioConverter);
    free(aacBuffer);
}

- (instancetype)initWithEncoderQueue:(dispatch_queue_t)encoderQueue callbackQueue:(dispatch_queue_t)callbackQueue {
    if (self = [super init]) {
        _encoderQueue  = encoderQueue;
        _callbackQueue = callbackQueue;
        audioConverter = NULL;
        pcmBufferSize  = 0;
        pcmBuffer      = NULL;
        aacBufferSize  = 1024;
        aacBuffer      = malloc(aacBufferSize * sizeof(uint8_t));
    }
    return self;
}

- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer completionBlock:(void (^)(NSData *encodedData, NSError *error))completionBlock {
    CFRetain(sampleBuffer);
    dispatch_async(self.encoderQueue, ^{
        NSData *data = nil;
        NSError *error = nil;
        
        if (!audioConverter) {
            [self createEncoder:sampleBuffer];
        }
        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        CFRetain(blockBuffer);
        OSStatus status = CMBlockBufferGetDataPointer(blockBuffer,
                                                      0,
                                                      NULL,
                                                      &pcmBufferSize,
                                                      &pcmBuffer);
        if (status != kCMBlockBufferNoErr) {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        }
        memset(aacBuffer, 0, aacBufferSize);
        
        AudioBufferList outAudioBufferList = {0};
        outAudioBufferList.mNumberBuffers = 1;
        outAudioBufferList.mBuffers[0].mNumberChannels = 1;
        outAudioBufferList.mBuffers[0].mDataByteSize = (int)aacBufferSize;
        outAudioBufferList.mBuffers[0].mData = aacBuffer;
        
        AudioStreamPacketDescription *outPacketDescription = NULL;
        UInt32 ioOutputDataPacketSize = 1;
        
        status = AudioConverterFillComplexBuffer(audioConverter,
                                                 inInputDataProc,
                                                 (__bridge void *)(self),
                                                 &ioOutputDataPacketSize,
                                                 &outAudioBufferList,
                                                 outPacketDescription);
        if (status == 0) {
            NSData *rawAAC = [NSData dataWithBytes:outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
            NSData *adtsHeader = [self adtsDataForPacketLength:rawAAC.length];
            NSMutableData *fullData = [NSMutableData dataWithData:adtsHeader];
            [fullData appendData:rawAAC];
            data = [fullData copy];
        } else {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        }
        if (completionBlock) {
            dispatch_async(self.callbackQueue, ^{
                completionBlock(data, error);
            });
        }
        CFRelease(sampleBuffer);
        CFRelease(blockBuffer);
    });
}

#pragma mark - private

/**
 *  创建编码参数
 */
- (void)createEncoder:(CMSampleBufferRef)sampleBuffer {
    CMAudioFormatDescriptionRef AFD = CMSampleBufferGetFormatDescription(sampleBuffer);
    AudioStreamBasicDescription pcmASBD = *CMAudioFormatDescriptionGetStreamBasicDescription(AFD);
    
    AudioStreamBasicDescription aacASBD = {0};
    aacASBD.mSampleRate       = pcmASBD.mSampleRate;
    aacASBD.mFormatID         = kAudioFormatMPEG4AAC;
    aacASBD.mFormatFlags      = kMPEG4Object_AAC_LC;
    aacASBD.mBytesPerPacket   = 0;
    aacASBD.mFramesPerPacket  = 1024;
    aacASBD.mBytesPerFrame    = 0;
    aacASBD.mChannelsPerFrame = 1;
    aacASBD.mBitsPerChannel   = 0;
    aacASBD.mReserved         = 0;
    AudioClassDescription *description = [self getAudioClassDescriptionWith:kAudioFormatMPEG4AAC from:kAppleSoftwareAudioCodecManufacturer];
    // 创建转换器
    OSStatus status = AudioConverterNewSpecific(&pcmASBD,
                                                &aacASBD,
                                                1,
                                                description,
                                                &audioConverter);
    if (status != 0) {
        NSLog(@"create converter fail: %d", (int)status);
    }
}

/**
 获取编码器

 @param type 编码类型
 @param manufacturer 软/硬编码
 */
- (AudioClassDescription *)getAudioClassDescriptionWith:(UInt32)type from:(UInt32)manufacturer {
    static AudioClassDescription desc;
    UInt32 size;
    
    //先获取buffer大小
    OSStatus status = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(type), &type, &size);
    if (status) {
        NSLog(@"error getting audio format propery info: %d", (int)(status));
        return nil;
    }
    
    unsigned int count = size / sizeof(AudioClassDescription);
    AudioClassDescription descriptions[count];
    
    status = AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(type), &type, &size, descriptions);
    if (status) {
        NSLog(@"error getting audio format propery: %d", (int)(status));
        return nil;
    }
    
    for (unsigned int i = 0; i < count; i++) {
        if ((type == descriptions[i].mSubType) && (manufacturer == descriptions[i].mManufacturer)) {
            memcpy(&desc, &(descriptions[i]), sizeof(desc));
            return &desc;
        }
    }
    return nil;
}

/**
 回调函数，复制PCM数据到缓冲区
 */
OSStatus inInputDataProc(AudioConverterRef inAudioConverter,
                         UInt32 *ioNumberDataPackets,
                         AudioBufferList *ioData,
                         AudioStreamPacketDescription **outDataPacketDescription,
                         void *inUserData) {
    AACHardEncoder *encoder = (__bridge AACHardEncoder *)(inUserData);
    
    //未考虑数据没有完全填充的情况
    ioData->mBuffers[0].mData = encoder->pcmBuffer;
    ioData->mBuffers[0].mDataByteSize = (int)encoder->pcmBufferSize;
    encoder->pcmBuffer = NULL;
    encoder->pcmBufferSize = 0;
    *ioNumberDataPackets = 1;
    
    return noErr;
}

/**
 生成ADTS头部
 */
- (NSData *)adtsDataForPacketLength:(NSUInteger)packetLength {
    int ADTSLength = 7;
    char *packet = malloc(sizeof(char) * ADTSLength);
    int profile = 2;
    int freqIdx = 4;
    int chanCfg = 1;
    NSUInteger fullLength = ADTSLength + packetLength;
    packet[0] = (char)0xFF;
    packet[1] = (char)0xF9;
    packet[2] = (char)(((profile - 1) << 6) + (freqIdx << 2) +(chanCfg >> 2));
    packet[3] = (char)(((chanCfg & 3) << 6) + (fullLength >> 11));
    packet[4] = (char)((fullLength & 0x7FF) >> 3);
    packet[5] = (char)(((fullLength & 7) << 5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:ADTSLength freeWhenDone:YES];
    return data;
}

@end
