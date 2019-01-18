//
//  SCNV12VideoFrame.m
//  Athena
//
//  Created by Theresa on 2018/12/28.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import "SCNV12VideoFrame.h"

@implementation SCNV12VideoFrame

- (instancetype)initWithAVPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (self = [super init]) {
        _pixelBuffer = pixelBuffer;
        _width = CVPixelBufferGetWidth(pixelBuffer);
        _height = CVPixelBufferGetHeight(pixelBuffer);
    }
    return self;
}

- (void)dealloc {
    if (_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
        _pixelBuffer = NULL;
    }
}

@end
