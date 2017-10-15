//
//  AACSoftEncoder.m
//  Athena
//
//  Created by S.C. on 2017/10/15.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#ifdef __cplusplus
extern "C" {
#endif
#include <libavutil/opt.h>
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#ifdef __cplusplus
};
#endif

#import "AACSoftEncoder.h"

@interface AACSoftEncoder () {
    AVFormatContext *pFormatCtx;
    AVOutputFormat *fmt;
    AVStream *audio_st;
    AVCodecContext *pCodecCtx;
    AVCodec *pCodec;
}

@end

@implementation AACSoftEncoder

- (instancetype)init {
    if (self = [super init]) {
        av_register_all();
        
    }
    return self;
}

- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer completionBlock:(void (^)(NSData *encodedData, NSError *error))completionBlock {
    CFRetain(sampleBuffer);
    dispatch_async(self.encoderQueue, ^{
        NSData *data = nil;
        NSError *error = nil;
        
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

        if (completionBlock) {
            dispatch_async(self.callbackQueue, ^{
                completionBlock(data, error);
            });
        }
        CFRelease(sampleBuffer);
        CFRelease(blockBuffer);
    });
}
@end

