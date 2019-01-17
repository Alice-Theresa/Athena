//
//  SCVideoFrame.m
//  Athena
//
//  Created by Theresa on 2018/12/28.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import "SCVideoFrame.h"

@implementation SCVideoFrame

- (instancetype)initWithAVPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (self = [super init]) {
        _pixelBuffer = pixelBuffer;
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
