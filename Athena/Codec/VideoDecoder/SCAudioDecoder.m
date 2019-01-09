//
//  SCAudioDecoder.m
//  Athena
//
//  Created by Theresa on 2019/01/09.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCAudioDecoder.h"
#import "SCFormatContext.h"

#include <libswresample/swresample.h>

@interface SCAudioDecoder () {
    
    SwrContext *_audio_swr_context;
    Float64 _samplingRate;
    UInt32 _channelCount;
}

@property (nonatomic, strong) SCFormatContext *context;

@end

@implementation SCAudioDecoder

- (instancetype)initWithFormatContext:(SCFormatContext *)formatContext {
    if (self = [super init]) {
        _context = formatContext;
        [self setupSwsContext];
    }
    return self;
}

- (void)setupSwsContext {
    _audio_swr_context = swr_alloc_set_opts(NULL,
                                            av_get_default_channel_layout(_channelCount),
                                            AV_SAMPLE_FMT_S16,
                                            _samplingRate,
                                            av_get_default_channel_layout([self.context fetchCodecContext]->channels),
                                            [self.context fetchCodecContext]->sample_fmt,
                                            [self.context fetchCodecContext]->sample_rate,
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

- (void)synchronizedDecode:(AVPacket)packet {

    av_packet_unref(&packet);
}

@end
