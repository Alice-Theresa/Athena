//
//  SCVideoFrame.h
//  Athena
//
//  Created by Skylar on 2019/11/8.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCFlowData.h"
#import <AVFoundation/AVFoundation.h>

@interface SCVideoFrame : SCFlowData <SCFrame>

@property (nonatomic, assign, readonly) NSUInteger width;
@property (nonatomic, assign, readonly) NSUInteger height;
@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;

@property (nonatomic, assign) AVFrame *core;
@property (nonatomic, assign) SCVideoFrameFormat videoFrameFormat;

- (uint8_t **)data;
- (void)fillData;

@end
