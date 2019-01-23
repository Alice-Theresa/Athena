//
//  SCAudioDecoder.m
//  Athena
//
//  Created by Theresa on 2019/01/09.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCAudioDecoder.h"
#import "SCFormatContext.h"
#import "SCAudioFrame.h"
#import "SCFrameQueue.h"

#include <libswresample/swresample.h>
#import <Accelerate/Accelerate.h>

@interface SCAudioDecoder () {
    
    AVFrame *_temp_frame;
    SwrContext *_audio_swr_context;
    Float64 _samplingRate;
    UInt32 _channelCount;
    
    void *_audio_swr_buffer;
    int _audio_swr_buffer_size;
}

@property (nonatomic, weak  ) SCFormatContext *context;
@property (nonatomic, assign) AVCodecContext *codecContext;

@end

@implementation SCAudioDecoder

- (void)dealloc {
    av_frame_free(&_temp_frame);
    swr_free(&_audio_swr_context);
}

- (instancetype)initWithFormatContext:(SCFormatContext *)formatContext {
    if (self = [super init]) {
        _context = formatContext;
        _codecContext = formatContext.audioCodecContext;
        _temp_frame = av_frame_alloc();
        [self setupSwsContext];
    }
    return self;
}

- (void)setupSwsContext {
    _samplingRate = 44100;
    _channelCount = 2;
    _audio_swr_context = swr_alloc_set_opts(NULL,
                                            av_get_default_channel_layout(_channelCount),
                                            AV_SAMPLE_FMT_S16,
                                            _samplingRate,
                                            av_get_default_channel_layout(self.codecContext->channels),
                                            self.codecContext->sample_fmt,
                                            self.codecContext->sample_rate,
                                            0,
                                            NULL);
    
    int result = swr_init(_audio_swr_context);
    NSError *error = nil;
    if (error || !_audio_swr_context) {
        if (_audio_swr_context) {
            swr_free(&_audio_swr_context);
        }
    }
}

- (NSArray<SCFrame *> *)decode:(AVPacket)packet {
    NSArray *defaultArray = @[];
    NSMutableArray *array = [NSMutableArray array];
    if (packet.data == NULL) {
        return defaultArray;
    }
    int result = avcodec_send_packet(self.codecContext, &packet);
    if (result < 0 && result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
        return defaultArray;
    }
    while (result >= 0) {
        result = avcodec_receive_frame(self.codecContext, _temp_frame);
        if (result < 0) {
            if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                return defaultArray;
            }
            break;
        }
        SCAudioFrame *frame = [self innerDecode:packet.size];
        if (frame) {
            [array addObject:frame];
        }
    }
    av_packet_unref(&packet);
    return [array copy];
}

- (SCAudioFrame *)innerDecode:(int)packetSize {
    if (!_temp_frame->data[0]) {
        return nil;
    }
    
    int numberOfFrames;
    void *audioDataBuffer;
    
    if (_audio_swr_context) {
        const int ratio = MAX(1, _samplingRate / self.codecContext->sample_rate) * MAX(1, _channelCount / self.codecContext->channels) * 2;
        const int buffer_size = av_samples_get_buffer_size(NULL, _channelCount, _temp_frame->nb_samples * ratio, AV_SAMPLE_FMT_S16, 1);
        
        if (!_audio_swr_buffer || _audio_swr_buffer_size < buffer_size) {
            _audio_swr_buffer_size = buffer_size;
            _audio_swr_buffer = realloc(_audio_swr_buffer, _audio_swr_buffer_size);
        }
        
        Byte *outyput_buffer[2] = {_audio_swr_buffer, 0};
        numberOfFrames = swr_convert(_audio_swr_context, outyput_buffer, _temp_frame->nb_samples * ratio, (const uint8_t **)_temp_frame->data, _temp_frame->nb_samples);
        NSError *error = nil;
        if (error) {
            return nil;
        }
        audioDataBuffer = _audio_swr_buffer;
    } else {
        // Todo
        @[][1];
    }
    
    SCAudioFrame *audioFrame = [[SCAudioFrame alloc] init];
//    audioFrame.packetSize = packetSize;
    audioFrame.position = av_frame_get_best_effort_timestamp(_temp_frame) * self.context.audioTimebase;
    audioFrame.duration = av_frame_get_pkt_duration(_temp_frame) * self.context.audioTimebase;
    
    if (audioFrame.duration == 0) {
        audioFrame.duration = audioFrame->length / (sizeof(float) * _channelCount * _samplingRate);
    }
    
    const NSUInteger numberOfElements = numberOfFrames * self->_channelCount;
    [audioFrame setSamplesLength:numberOfElements * sizeof(float)];
    
    float scale = 1.0 / (float)INT16_MAX ;
    vDSP_vflt16((SInt16 *)audioDataBuffer, 1, audioFrame->samples, 1, numberOfElements);
    vDSP_vsmul(audioFrame->samples, 1, &scale, audioFrame->samples, 1, numberOfElements);
    
    return audioFrame;
}

@end
