//
//  SCAudioDescriptor.m
//  Athena
//
//  Created by Skylar on 2019/11/3.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCAudioDescriptor.h"
#import "SCFrame.h"

@implementation SCAudioDescriptor

- (instancetype)init {
    if (self = [super init]) {
        _format = AV_SAMPLE_FMT_FLTP;
        _sampleRate = 44100;
        _numberOfChannels = 2;
        _channelLayout = av_get_default_channel_layout(2);
    }
    return self;
}
- (instancetype)initWithFrame:(SCFrame *)frame {
    if (self = [super init]) {
        _format = frame.core->format;
        _sampleRate = frame.core->sample_rate;
        _numberOfChannels = frame.core->channels;
        _channelLayout = frame.core->channel_layout ? frame.core->channel_layout : av_get_default_channel_layout(frame.core->channels);
    }
    return self;
}


@end
