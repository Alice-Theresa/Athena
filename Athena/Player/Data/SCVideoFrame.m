//
//  SCVideoFrame.m
//  Athena
//
//  Created by Theresa on 2018/12/28.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import "SCVideoFrame.h"

@interface SCVideoFrame ()
{
    int _linesize[8];
    uint8_t *_data[8];
}
@end

@implementation SCVideoFrame

@synthesize core = _core;
@synthesize type = _type;

- (instancetype)init {
    if (self = [super init]) {
        self->_core = av_frame_alloc();
    }
    return self;
}

- (void)dealloc {
    if (self.core) {
        av_frame_free(&self->_core);
    }
}

- (int *)linesize {
    return self->_linesize;
}

- (uint8_t **)data {
    return self->_data;
}

- (void)fillData {
    AVFrame *frame = self.core;
//    self->_descriptor = [[SGVideoDescriptor alloc] initWithFrame:frame];
    if (frame->format == AV_PIX_FMT_VIDEOTOOLBOX) {
        _pixelBuffer = (CVPixelBufferRef)(frame->data[3]);
        _width = CVPixelBufferGetWidth(_pixelBuffer);
        _height = CVPixelBufferGetHeight(_pixelBuffer);
//        self->_descriptor.cv_format = CVPixelBufferGetPixelFormatType(self->_pixelBuffer);
    } else {
        _type = SCFrameTypeI420;
        _width = frame->width;
        _height = frame->height;
    }
    for (int i = 0; i < 8; i++) {
        self->_data[i] = frame->data[i];
        self->_linesize[i] = frame->linesize[i];
    }
}


@end
