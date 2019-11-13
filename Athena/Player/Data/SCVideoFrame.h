//
//  SCVideoFrame.h
//  Athena
//
//  Created by Skylar on 2019/11/8.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCFlowData.h"
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCVideoFrame : NSObject <SCFrame, SCFlowData>
@property (nonatomic, assign) NSTimeInterval timeStamp;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSUInteger width;
@property (nonatomic, assign, readonly) NSUInteger height;

@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;
@property (nonatomic, assign) AVFrame *core;
@property (nonatomic, strong) SCCodecDescriptor *codecDescriptor;
@property (nonatomic, assign) SCFrameType type;

- (uint8_t **)data;
- (void)fillData;

@end

NS_ASSUME_NONNULL_END
