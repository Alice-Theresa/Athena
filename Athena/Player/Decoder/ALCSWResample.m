//
//  SCSWResample.m
//  Athena
//
//  Created by Skylar on 2019/11/3.
//  Copyright © 2019 Theresa. All rights reserved.
//

#include <libswresample/swresample.h>
#import "ALCSWResample.h"
#import "ALCAudioDescriptor.h"

@interface ALCSWResample ()

{
    AVBufferRef *_buffer[8];
}

@property (nonatomic, readonly) SwrContext *context;

@end

@implementation ALCSWResample

- (void)dealloc {
    if (self.context) {
        swr_free(&self->_context);
        self->_context = nil;
    }
    for (int i = 0; i < 8; i++) {
        av_buffer_unref(&self->_buffer[i]);
        self->_buffer[i] = nil;
    }
}

- (BOOL)open {
    if (!self->_inputDescriptor || !self->_outputDescriptor) {
        return NO;
    }
    self->_context = swr_alloc_set_opts(NULL,
                                        self.outputDescriptor.channelLayout,
                                        self.outputDescriptor.format,
                                        self.outputDescriptor.sampleRate,
                                        self.inputDescriptor.channelLayout,
                                        self.inputDescriptor.format,
                                        self.inputDescriptor.sampleRate,
                                        0, NULL);
    if (swr_init(self.context) < 0) {
        return NO;
    }
    return YES;
}

- (int)write:(uint8_t **)data nb_samples:(int)nb_samples {
    int numberOfPlanes = self->_outputDescriptor.numberOfPlanes;
    int numberOfSamples = swr_get_out_samples(self->_context, nb_samples);
    int linesize = [self->_outputDescriptor linesize:numberOfSamples];
    uint8_t *o_data[8] = {NULL};
    for (int i = 0; i < numberOfPlanes; i++) {
        if (!self->_buffer[i] || self->_buffer[i]->size < linesize) {
            av_buffer_realloc(&self->_buffer[i], linesize);
        }
        o_data[i] = self->_buffer[i]->data;
    }
    return swr_convert(self.context,
                       (uint8_t **)o_data,
                       numberOfSamples,
                       (const uint8_t **)data,
                       nb_samples);
}

- (int)read:(uint8_t **)data nb_samples:(int)nb_samples {
    int numberOfPlanes = self->_outputDescriptor.numberOfPlanes;
    int linesize = [self->_outputDescriptor linesize:nb_samples];
    for (int i = 0; i < numberOfPlanes; i++) {
        memcpy(data[i], self->_buffer[i]->data, linesize);
    }
    return nb_samples;
}

@end
