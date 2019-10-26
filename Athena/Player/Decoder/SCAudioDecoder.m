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
#import "SCPacket.h"
#import "SCCodecContext.h"
#import "SCCodecDescriptor.h"

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

@property (nonatomic, strong) SCCodecContext *codecContext;
@property (nonatomic, strong) SCFormatContext *context;

@end

@implementation SCAudioDecoder

- (void)dealloc {
    av_frame_free(&_temp_frame);
    swr_free(&_audio_swr_context);
    NSLog(@"Audio Decoder dealloc");    
}

- (instancetype)initWithFormatContext:(SCFormatContext *)formatContext {
    if (self = [super init]) {
        _context = formatContext;
        _temp_frame = av_frame_alloc();
        
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
                                            av_get_default_channel_layout(self.codecContext.core->channels),
                                            self.codecContext.core->sample_fmt,
                                            self.codecContext.core->sample_rate,
                                            0,
                                            NULL);
    
    int result = swr_init(_audio_swr_context);
    if (result < 0 || !_audio_swr_context) {
        if (_audio_swr_context) {
            swr_free(&_audio_swr_context);
        }
    }
}

- (void)checkCodec:(SCPacket *)packet {
    if (!self.codecContext) {
        self.codecContext = [[SCCodecContext alloc] initWithTimebase:packet.codecDescriptor.timebase
                                                            codecpar:packet.codecDescriptor.codecpar];
        [self setupSwsContext];
    }
}

- (NSArray<SCFrame *> *)decode:(SCPacket *)packet {
    [self checkCodec:packet];
    NSArray *defaultArray = @[];
    NSMutableArray *array = [NSMutableArray array];
    if (packet.core->data == NULL) {
        return defaultArray;
    }
    int result = avcodec_send_packet(self.codecContext.core, packet.core);
    if (result < 0 && result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
        return defaultArray;
    }
    while (result >= 0) {
        result = avcodec_receive_frame(self.codecContext.core, _temp_frame);
        if (result < 0) {
            if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                return defaultArray;
            }
            break;
        }
        SCAudioFrame *frame = [self innerDecode:packet.core->size];
        if (frame) {
            [array addObject:frame];
        }
    }
    return [array copy];
}

- (SCAudioFrame *)innerDecode:(int)packetSize {
    if (!_temp_frame->data[0]) {
        return nil;
    }
    
    int numberOfFrames;
    void *audioDataBuffer;
    
    if (_audio_swr_context) {
        const int ratio = MAX(1, _samplingRate / self.codecContext.core->sample_rate) * MAX(1, _channelCount / self.codecContext.core->channels) * 2;
        const int buffer_size = av_samples_get_buffer_size(NULL, _channelCount, _temp_frame->nb_samples * ratio, AV_SAMPLE_FMT_S16, 1);
        
        if (!_audio_swr_buffer || _audio_swr_buffer_size < buffer_size) {
            _audio_swr_buffer_size = buffer_size;
            _audio_swr_buffer = realloc(_audio_swr_buffer, _audio_swr_buffer_size);
        }
        
        Byte *outyput_buffer[2] = {_audio_swr_buffer, 0};
        numberOfFrames = swr_convert(_audio_swr_context,
                                     outyput_buffer,
                                     _temp_frame->nb_samples * ratio,
                                     (const uint8_t **)_temp_frame->data,
                                     _temp_frame->nb_samples);
        audioDataBuffer = _audio_swr_buffer;
    } else {
        // Todo
        @[][1];
    }
    
    SCAudioFrame *audioFrame = [[SCAudioFrame alloc] init];
    audioFrame.position = av_frame_get_best_effort_timestamp(_temp_frame) * self.context.audioTimebase;
    audioFrame.duration = av_frame_get_pkt_duration(_temp_frame) * self.context.audioTimebase;
    
    const NSUInteger numberOfElements = numberOfFrames * _channelCount;
    NSMutableData *pcmData = [NSMutableData dataWithLength:numberOfElements * sizeof(SInt16)];
    memcpy(pcmData.mutableBytes, audioDataBuffer, numberOfElements * sizeof(SInt16));
    audioFrame.sampleData = pcmData;
    return audioFrame;
}

@end
