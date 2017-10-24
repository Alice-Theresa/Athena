//
//  H264HardwareDecoder.m
//  Athena
//
//  Created by Theresa on 2017/10/24.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <VideoToolbox/VideoToolbox.h>
#import "H264HardwareDecoder.h"

@interface H264HardwareDecoder () {
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
}

@end

@implementation H264HardwareDecoder

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)setup {
    const uint8_t* const parameterSetPointers[2] = { _sps, _pps };
    const size_t parameterSetSizes[2] = { _spsSize, _ppsSize };
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2,
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4,
                                                                          &_decoderFormatDescription);
    NSDictionary *attributes = @{
                                 (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],
                                 // 硬解必须是 kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                 // 或者是kCVPixelFormatType_420YpCbCr8Planar
                                 // 因为iOS是  nv12  其他是nv21
                                 (id)kCVPixelBufferWidthKey : [NSNumber numberWithInt:1920],
                                 (id)kCVPixelBufferHeightKey : [NSNumber numberWithInt:1080],
                                 (id)kCVPixelBufferOpenGLCompatibilityKey : [NSNumber numberWithBool:YES]
                                 };
    
    
    VTDecompressionOutputCallbackRecord callBackRecord;
    callBackRecord.decompressionOutputCallback = didDecompress;
    callBackRecord.decompressionOutputRefCon = (__bridge void *)self;
    status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                          _decoderFormatDescription,
                                          NULL,
                                          (__bridge CFDictionaryRef)attributes,
                                          &callBackRecord,
                                          &_deocderSession);
    VTSessionSetProperty(_deocderSession, kVTDecompressionPropertyKey_ThreadCount, (__bridge CFTypeRef)[NSNumber numberWithInt:1]);
    VTSessionSetProperty(_deocderSession, kVTDecompressionPropertyKey_RealTime, kCFBooleanTrue);
}


/**
 解码回调函数
 */
static void didDecompress(void *decompressionOutputRefCon,
                          void *sourceFrameRefCon,
                          OSStatus status,
                          VTDecodeInfoFlags infoFlags,
                          CVImageBufferRef pixelBuffer,
                          CMTime presentationTimeStamp,
                          CMTime presentationDuration ) {
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
    H264HardwareDecoder *decoder = (__bridge H264HardwareDecoder *)decompressionOutputRefCon;
//    if (decoder.delegate != nil)
//    {
//        [decoder.delegate displayDecodedFrame:pixelBuffer];
//    }
}

- (void)clearDecoder {
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
    _spsSize = 0;
    _ppsSize = 0;
}

@end
