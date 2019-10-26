//
//  SCCodecContext.m
//  Athena
//
//  Created by Skylar on 2019/10/26.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import <libavutil/hwcontext.h>
#import "SCCodecContext.h"
#import "SCFrame.h"
#import "SCPacket.h"

@interface SCCodecContext ()

@property (nonatomic, assign) AVRational timebase;
@property (nonatomic, assign) AVCodecParameters *codecpar;

@end

@implementation SCCodecContext

- (void)dealloc {
    [self close];
}

- (instancetype)initWithTimebase:(AVRational)timebase codecpar:(AVCodecParameters *)codecpar {
    if (self = [super init]) {
        _timebase = timebase;
        _codecpar = codecpar;
        [self open];
    }
    return self;
}

- (BOOL)open {
    if (!self.codecpar) {
        return NO;
    }
    self.core = [self createCcodecContext];
    if (!self.core) {
        return NO;
    }
    return YES;
}

- (void)close {
    if (self.core) {
        avcodec_free_context(&self->_core);
        self.core = nil;
    }
}

- (void)flush {
    if (self.core) {
        avcodec_flush_buffers(self.core);
    }
}

- (AVCodecContext *)createCcodecContext {
    AVCodecContext *codecContext = avcodec_alloc_context3(NULL);
    if (!codecContext) {
        return nil;
    }
//    codecContext->opaque = (__bridge void *)self;
    
    int result = avcodec_parameters_to_context(codecContext, self.codecpar);
//    NSError *error = SGGetFFError(result, SGActionCodeCodecSetParametersToContext);
    if (result < 0) {
        avcodec_free_context(&codecContext);
        return nil;
    }
    codecContext->pkt_timebase = self.timebase;
    if (self.codecpar->codec_id == AV_CODEC_ID_H264 || self.codecpar->codec_id == AV_CODEC_ID_H265) {
        codecContext->get_format = SCCodecContextGetFormat;
    }
    
    AVCodec *codec = avcodec_find_decoder(codecContext->codec_id);
    if (!codec) {
        avcodec_free_context(&codecContext);
        return nil;
    }
    codecContext->codec_id = codec->id;
    
    AVDictionary *opts = NULL;//SGDictionaryNS2FF(self->_options.options);
//    if (self->_options.threadsAuto &&
//        !av_dict_get(opts, "threads", NULL, 0))
//    {
        av_dict_set(&opts, "threads", "auto", 0);
//    }
//    if (self->_options.refcountedFrames &&
//        !av_dict_get(opts, "refcounted_frames", NULL, 0) &&
//        (codecContext->codec_type == AVMEDIA_TYPE_VIDEO || codecContext->codec_type == AVMEDIA_TYPE_AUDIO))
//    {
        av_dict_set(&opts, "refcounted_frames", "1", 0);
//    }
    
    result = avcodec_open2(codecContext, codec, &opts);
    
    if (opts) {
        av_dict_free(&opts);
    }
    
//    error = SGGetFFError(result, SGActionCodeCodecOpen2);
    if (result < 0) {
        avcodec_free_context(&codecContext);
        return nil;
    }
    
    return codecContext;
}

static enum AVPixelFormat SCCodecContextGetFormat(struct AVCodecContext *s, const enum AVPixelFormat *fmt) {
    for (int i = 0; fmt[i] != AV_PIX_FMT_NONE; i++) {
        if (fmt[i] == AV_PIX_FMT_VIDEOTOOLBOX) {
            AVBufferRef *device_ctx = av_hwdevice_ctx_alloc(AV_HWDEVICE_TYPE_VIDEOTOOLBOX);
            if (!device_ctx) {
                break;
            }
            AVBufferRef *frames_ctx = av_hwframe_ctx_alloc(device_ctx);
            av_buffer_unref(&device_ctx);
            if (!frames_ctx) {
                break;
            }
            AVHWFramesContext *frames_ctx_data = (AVHWFramesContext *)frames_ctx->data;
            frames_ctx_data->format            = AV_PIX_FMT_VIDEOTOOLBOX;
            frames_ctx_data->sw_format         = AV_PIX_FMT_NV12;
            frames_ctx_data->width             = s->width;
            frames_ctx_data->height            = s->height;
            int err = av_hwframe_ctx_init(frames_ctx);
            if (err < 0) {
                av_buffer_unref(&frames_ctx);
                break;
            }
            s->hw_frames_ctx = frames_ctx;
            return fmt[i];
        }
    }
    return fmt[0];
}

@end
