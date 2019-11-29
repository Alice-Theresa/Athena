//
//  SCCodecContext.m
//  Athena
//
//  Created by Skylar on 2019/10/26.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import <libavutil/hwcontext.h>
#import "ALCCodecContext.h"
#import "ALCPacket.h"
#import "ALCVideoFrame.h"
#import "ALCAudioFrame.h"

@interface ALCCodecContext ()

@property (nonatomic, copy  ) Class frameClass;
@property (nonatomic, assign) AVRational timebase;
@property (nonatomic, assign) AVCodecParameters *codecpar;

@end

@implementation ALCCodecContext

- (void)dealloc {
    [self close];
}

- (instancetype)initWithTimebase:(AVRational)timebase codecpar:(AVCodecParameters *)codecpar frameClass:(Class)frameClass {
    if (self = [super init]) {
        _frameClass = frameClass;
        _timebase = timebase;
        _codecpar = codecpar;
        _core = [self createCcodecContext];
    }
    return self;
}

- (NSArray<id<ALCFrame>> *)decode:(ALCPacket *)packet {
    NSArray *defaultArray = @[];
    NSMutableArray *array = [NSMutableArray array];
    int result = avcodec_send_packet(self.core, packet.core);
    if (result < 0) {
        return defaultArray;
    }
    while (result >= 0) {
        id<ALCFrame> frame = [[self.frameClass alloc] init]; 
        result = avcodec_receive_frame(self.core, frame.core);
        if (result < 0) {
            if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                return defaultArray;
            }
            break;
        } else {
            [array addObject:frame];
        }
    }
    return array;
}

- (void)flush {
    if (self.core) {
        avcodec_flush_buffers(self.core);
    }
}

- (void)close {
    if (self.core) {
        avcodec_free_context(&self->_core);
    }
}

- (AVCodecContext *)createCcodecContext {
    AVCodecContext *codecContext = avcodec_alloc_context3(NULL);
    if (!codecContext) {
        return nil;
    }
    
    int result = avcodec_parameters_to_context(codecContext, self.codecpar);
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
    
    AVDictionary *opts = NULL;
    av_dict_set(&opts, "threads", "auto", 0);
    av_dict_set(&opts, "refcounted_frames", "1", 0);
    
    result = avcodec_open2(codecContext, codec, &opts);
    if (opts) {
        av_dict_free(&opts);
    }
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
