//
//  AACSoftEncoder.m
//  Athena
//
//  Created by S.C. on 2017/10/15.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#include <libavutil/opt.h>
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>

#import "AACSoftEncoder.h"

#define ENCODE_SIZE 1024

@interface AACSoftEncoder () {
    AVCodecContext *codecContext;
    AVCodec *codec;
    AVPacket packet;
    AVFrame *frame;
    uint8_t *frameBuf;
    long length;
    long oneSecBytes;
    
    char *pcmBuffer;
    size_t pcmBufferSize;
}

@property (nonatomic, strong) dispatch_queue_t encoderQueue;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;

@end

@implementation AACSoftEncoder

- (void)dealloc {
    avcodec_close(codecContext);
    av_free(codecContext);
    av_freep(&frame->data[0]);
    av_frame_free(&frame);
}

- (instancetype)initWithEncoderQueue:(dispatch_queue_t)encoderQueue callbackQueue:(dispatch_queue_t)callbackQueue {
    if (self = [super init]) {
        _encoderQueue  = encoderQueue;
        _callbackQueue = callbackQueue;
        if (![self setup]) {
            return nil;
        }
    }
    return self;
}

- (BOOL)setup {
    oneSecBytes = 44100 * 1 * 2;
    avcodec_register_all();
    
    NSString *codecName = @"libfdk_aac";
    codec = avcodec_find_encoder_by_name(codecName.UTF8String);
    if (!codec) {
        return NO;
    }
    
    codecContext = avcodec_alloc_context3(codec);
    if (!codecContext) {
        return NO;
    }
    
    codecContext->codec_id       = AV_CODEC_ID_AAC;
    codecContext->codec_type     = AVMEDIA_TYPE_AUDIO;
    codecContext->sample_fmt     = AV_SAMPLE_FMT_S16;
    codecContext->sample_rate    = 44100;
    codecContext->channel_layout = AV_CH_LAYOUT_MONO;
    codecContext->channels       = av_get_channel_layout_nb_channels(codecContext->channel_layout);
    codecContext->bit_rate       = 96000;
    codecContext->frame_size     = ENCODE_SIZE;
    codecContext->profile        = FF_PROFILE_AAC_HE;
    
    int ret = 0;
    if ((ret = avcodec_open2(codecContext, codec, NULL) < 0)) {
        return NO;
    }
    
    frame = av_frame_alloc();
    frame->format = codecContext->sample_fmt;
    frame->nb_samples = ENCODE_SIZE;
    int size = av_samples_get_buffer_size(NULL, codecContext->channels, ENCODE_SIZE, codecContext->sample_fmt, 1);
    frameBuf = (uint8_t*)av_malloc(size);
    avcodec_fill_audio_frame(frame, codecContext->channels, codecContext->sample_fmt, frameBuf, size, 1);
    return YES;
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
        
        memcpy(frameBuf, pcmBuffer, pcmBufferSize);
        frame->data[0] = frameBuf;
        
        frame->pts = length/oneSecBytes;
        
        //Encode
        int ret = avcodec_send_frame(codecContext, frame);
        ret = avcodec_receive_packet(codecContext, &packet);
        if(ret < 0){
            
        }
        data = [NSData dataWithBytes:packet.data length:packet.size];
        av_packet_unref(&packet);
        
        if (completionBlock) {
            dispatch_async(self.callbackQueue, ^{
                completionBlock(data, error);
            });
        }
        CFRelease(sampleBuffer);
        CFRelease(blockBuffer);
    });
}
/*
- (void)free {
    int ret = [self flushEncoder];
    if (ret < 0) {
        
        printf("Flushing encoder failed\n");
    }
    avcodec_close(_pCodecCtx);
    av_free(_pCodecCtx);
    av_freep(&_pFrame->data[0]);
    av_frame_free(&_pFrame);
}

- (int)flushEncoder {
    int ret;
    int got_frame;
    AVPacket enc_pkt;
    
    while (1) {
        enc_pkt.data = NULL;
        enc_pkt.size = 0;
        av_init_packet(&enc_pkt);
        ret = avcodec_encode_audio2 (_pCodecCtx, &enc_pkt, NULL, &got_frame);
        av_frame_free(NULL);
        if (ret < 0)
            break;
        if (!got_frame){
            ret=0;
            break;
        }
        printf("Flush Encoder: Succeed to encode 1 frame!\tsize:%5d\n",enc_pkt.size);
        //TODO:编码数据回调
    }
    return ret;
}*/

@end

