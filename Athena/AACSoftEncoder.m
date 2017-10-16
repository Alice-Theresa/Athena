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
    AVCodecContext                      *_pCodecCtx;
    AVCodec                             *_pCodec;
    AVPacket                             _pkt;
    AVFrame                             *_pFrame;
    uint8_t                             *_frameBuf;
    long                                _length;
    long                                _oneSecBytes;
}

@end

@implementation AACSoftEncoder

- (void)dealloc {
    
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _oneSecBytes = 44100 * 1 * 2;
    avcodec_register_all();
    
    NSString *codecName = @"libfdk_aac";
    _pCodec = avcodec_find_encoder_by_name(codecName.UTF8String);
    if (!_pCodec) {
        
    }
    
    _pCodecCtx = avcodec_alloc_context3(_pCodec);
    if (!_pCodecCtx) {
        
    }
    
    _pCodecCtx->codec_id       = AV_CODEC_ID_AAC;
    _pCodecCtx->codec_type     = AVMEDIA_TYPE_AUDIO;
    _pCodecCtx->sample_fmt     = AV_SAMPLE_FMT_S16;
    _pCodecCtx->sample_rate    = 44100;
    _pCodecCtx->channel_layout = AV_CH_LAYOUT_MONO;
    _pCodecCtx->channels       = av_get_channel_layout_nb_channels(_pCodecCtx->channel_layout);
    _pCodecCtx->bit_rate       = 96000;
    _pCodecCtx->frame_size     = ENCODE_SIZE;
    
    int ret = 0;
    if ((ret = avcodec_open2(_pCodecCtx, _pCodec, NULL) < 0)) {
        
    }
    
    _pFrame = av_frame_alloc();
    _pFrame->format = _pCodecCtx->sample_fmt;
    _pFrame->nb_samples = ENCODE_SIZE;
    int size = av_samples_get_buffer_size(NULL, _pCodecCtx->channels,ENCODE_SIZE,_pCodecCtx->sample_fmt, 1);
    _frameBuf = (uint8_t*)av_malloc(size);
    avcodec_fill_audio_frame(_pFrame, _pCodecCtx->channels, _pCodecCtx->sample_fmt, _frameBuf, size, 1);
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
        
        memcpy(_frameBuf, pcmBuffer, pcmBufferSize);
        _pFrame->data[0] = _frameBuf;
        
        _pFrame->pts = _length/_oneSecBytes;
        
        //Encode
        int ret = avcodec_send_frame(_pCodecCtx, _pFrame);
        ret = avcodec_receive_packet(_pCodecCtx, &_pkt);
        if(ret < 0){
            
        }
        data = [NSData dataWithBytes:_pkt.data length:_pkt.size];
        av_packet_unref(&_pkt);
        
        if (completionBlock) {
            dispatch_async(self.callbackQueue, ^{
                completionBlock(data, error);
            });
        }
        CFRelease(sampleBuffer);
        CFRelease(blockBuffer);
    });
}

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
}

@end

