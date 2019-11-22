//
//  SCAudioFrame.m
//  Athena
//
//  Created by Skylar on 2019/11/8.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCAudioFrame.h"
#import "SCAudioDescriptor.h"

@implementation SCAudioFrame {
    uint8_t *_data[8];
}

@synthesize mediaType = _mediaType;

+ (instancetype)audioFrameWithDescriptor:(SCAudioDescriptor *)descriptor numberOfSamples:(int)numberOfSamples {
    SCAudioFrame *frame = [[SCAudioFrame alloc] init];
    frame.core->format = descriptor.format;
    frame.core->sample_rate = descriptor.sampleRate;
    frame.core->channels = descriptor.numberOfChannels;
    frame.core->channel_layout = descriptor.channelLayout;
    frame.core->nb_samples = numberOfSamples;
    int linesize = [descriptor linesize:numberOfSamples];
    int numberOfPlanes = descriptor.numberOfPlanes;
    for (int i = 0; i < numberOfPlanes; i++) {
        uint8_t *data = av_mallocz(linesize);
        memset(data, 0, linesize);
        AVBufferRef *buffer = av_buffer_create(data, linesize, av_buffer_default_free, NULL, 0);
        frame.core->buf[i] = buffer;
        frame.core->data[i] = buffer->data;
        frame.core->linesize[i] = buffer->size;
    }
    return frame;
}

- (instancetype)init {
    if (self = [super init]) {
        _core = av_frame_alloc();
        _mediaType = SCMediaTypeAudio;
    }
    return self;
}

- (void)dealloc {
    if (self.core) {
        av_frame_unref(self->_core);
        av_frame_free(&self->_core);
        self->_core = nil;
    }
    for (int i = 0; i < 8; i++) {
        self->_data[i] = nil;
    }
}

- (uint8_t **)data {
    return self->_data;
}

- (void)fillData {
    AVFrame *frame = self.core;
    self.numberOfSamples = frame->nb_samples;
    for (int i = 0; i < 8; i++) {
        self->_data[i] = frame->data[i];
    }
}

@end
