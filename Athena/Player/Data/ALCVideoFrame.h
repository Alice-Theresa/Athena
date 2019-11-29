//
//  SCVideoFrame.h
//  Athena
//
//  Created by Skylar on 2019/11/8.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "ALCFlowData.h"
#import <AVFoundation/AVFoundation.h>

@interface ALCVideoFrame : ALCFlowData <ALCFrame>

@property (nonatomic, assign, readonly) NSUInteger width;
@property (nonatomic, assign, readonly) NSUInteger height;
@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;

@property (nonatomic, assign) AVFrame *core;
@property (nonatomic, assign) ALCVideoFrameFormat videoFrameFormat;

- (uint8_t **)data;
- (void)fillData;

@end
