//
//  H264HardwareEncoder.m
//  Athena
//
//  Created by Theresa on 2017/10/20.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "H264HardwareEncoder.h"

@interface H264HardwareEncoder () {
    VTCompressionSessionRef _encodeSesion;
}

@property (nonatomic, assign) NSInteger frameID;

@end

@implementation H264HardwareEncoder

- (instancetype)init {
    if (self = [super init]) {
        _frameID = 0;
    }
    return self;
}

/**
 初始化编码器

 @param imageBuffer 图像数据
 */
- (void)setupEncodeSession:(CVImageBufferRef)imageBuffer {
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    OSStatus status = VTCompressionSessionCreate(kCFAllocatorDefault,
                                                 (int32_t)width,
                                                 (int32_t)height,
                                                 kCMVideoCodecType_H264,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 didCompressH264,
                                                 (__bridge void *)(self),
                                                 &_encodeSesion);
    if (status != noErr) {
        NSLog(@"VTCompressionSessionCreate failed. ret=%d", (int)status);
    }
    
    // 设置实时编码输出（避免延迟）
    VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
    
    // 设置关键帧（GOPsize)间隔
    int frameInterval = 10;
    CFNumberRef  frameIntervalRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &frameInterval);
    VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_MaxKeyFrameInterval, frameIntervalRef);
    
    // 设置期望帧率
    int fps = 30;
    CFNumberRef  fpsRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &fps);
    VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_ExpectedFrameRate, fpsRef);
    
    
    //设置码率，均值，单位是bps
    long bitRate = 2000 * 1000 * 8;
    CFNumberRef bitRateRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
    VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_AverageBitRate, bitRateRef);
    
    //设置码率，上限，单位是byte
    long bitRateLimit = 3000 * 1000;
    CFNumberRef bitRateLimitRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRateLimit);
    VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_DataRateLimits, bitRateLimitRef);
    
    // 开始编码
    VTCompressionSessionPrepareToEncodeFrames(_encodeSesion);
}

- (void)teardown {
    VTCompressionSessionCompleteFrames(_encodeSesion, kCMTimeInvalid);
    VTCompressionSessionInvalidate(_encodeSesion);
    CFRelease(_encodeSesion);
    _encodeSesion = NULL;
}

- (void)encodeSampleBuffer:(CVImageBufferRef)imageBuffer {
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    if (!_encodeSesion) {
        [self setupEncodeSession:imageBuffer];
    }
    self.frameID++;
    CMTime pts = CMTimeMake(self.frameID, 30);
    
    // 送入编码器编码
    OSStatus statusCode = VTCompressionSessionEncodeFrame(_encodeSesion, imageBuffer, pts, kCMTimeInvalid, NULL, NULL, NULL);
    if (statusCode != noErr) {
        NSError *error = [NSError errorWithDomain:@"编码失败" code:0 userInfo:nil];
        [self.delegate encodedResult:nil error:error];
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

/**
 编码完成回调
 */
void didCompressH264(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer) {
    if (status != 0) {
        return;
    }
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        return;
    }
    H264HardwareEncoder *encoder = (__bridge H264HardwareEncoder *)outputCallbackRefCon;
    
    CFArrayRef attachmentsarray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    CFDictionaryRef dict = CFArrayGetValueAtIndex(attachmentsarray, 0);
    Boolean keyframe = !CFDictionaryContainsKey(dict, kCMSampleAttachmentKey_NotSync);
    
    // 判断当前帧是否为关键帧 是则获取sps、pps数据
    if (keyframe) {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        const uint8_t *sparameterSet, *pparameterSet;
        size_t spsParameterSetSize, ppsParameterSetSize;
        
        OSStatus spsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &spsParameterSetSize, NULL, NULL);
        OSStatus ppsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &ppsParameterSetSize, NULL, NULL);
        
        // 找到sps、pps
        if (spsStatus == noErr && ppsStatus == noErr) {
            NSData *sps = [NSData dataWithBytes:sparameterSet length:spsParameterSetSize];
            NSData *pps = [NSData dataWithBytes:pparameterSet length:ppsParameterSetSize];
            if (encoder) {
                [encoder processSPS:sps PPS:pps];
            }
        }
    }
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4; // 返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
        
        // 循环获取nalu数据
        while (bufferOffset < totalLength - AVCCHeaderLength) {
            uint32_t NALUnitLength = 0;
            // Read the NAL unit length
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
            
            // 从大端转系统端
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            
            NSData *data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
            [encoder processEncodedData:data];
            
            // Move to the next NAL unit in the block buffer
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
    }
}

#pragma mark - 编码后数据处理

/**
 处理sps、pps数据

 @param sps sps数据
 @param pps pps数据
 */
- (void)processSPS:(NSData *)sps PPS:(NSData *)pps {
    NSMutableData *temp = [NSMutableData data];
    [temp appendData:[self buildHeader]];
    [temp appendData:sps];
    [temp appendData:[self buildHeader]];
    [temp appendData:pps];
    [self.delegate encodedResult:[temp copy] error:nil];
}

/**
 处理编码数据

 @param data 编码数据
 */
- (void)processEncodedData:(NSData *)data {
    NSMutableData *temp = [NSMutableData data];
    [temp appendData:[self buildHeader]];
    [temp appendData:data];
    [self.delegate encodedResult:[temp copy] error:nil];
}

/**
 构造数据头部

 @return 数据头部
 */
- (NSData *)buildHeader {
    const static char bytes[] = "\x00\x00\x00\x01";
    size_t length = sizeof(bytes) - 1; // 字符串结尾包含'\0'
    NSData *byteHeader = [NSData dataWithBytes:bytes length:length];
    return byteHeader;
}

@end
