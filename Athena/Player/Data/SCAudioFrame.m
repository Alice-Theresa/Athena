//
//  SCAudioFrame.m
//  Athena
//
//  Created by Theresa on 2019/01/09.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCAudioFrame.h"

@implementation SCAudioFrame {
    uint8_t *_data[8];
}

@synthesize core = _core;

- (instancetype)init {
    if (self = [super init]) {
        _core = av_frame_alloc();
    }
    return self;
}

- (void)dealloc {
    if (self.core) {
        av_frame_free(&self->_core);
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
