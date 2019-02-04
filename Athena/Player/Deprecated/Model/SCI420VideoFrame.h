//
//  SCI420VideoFrame.h
//  Athena
//
//  Created by Theresa on 2019/01/17.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import "SCFrame.h"
#import "Athena-Swift.h"

typedef NS_ENUM(int, SGYUVChannel) {
    SGYUVChannelLuma = 0,
    SGYUVChannelChromaB = 1,
    SGYUVChannelChromaR = 2,
    SGYUVChannelCount = 3,
};

NS_ASSUME_NONNULL_BEGIN

@interface SCI420VideoFrame : SCFrame <RenderDataI420>

@property (nonatomic, assign, readonly) NSUInteger width;
@property (nonatomic, assign, readonly) NSUInteger height;

@property (nonatomic, assign, readonly) UInt8 *luma_channel_pixels;
@property (nonatomic, assign, readonly) UInt8 *chromaB_channel_pixels;
@property (nonatomic, assign, readonly) UInt8 *chromaR_channel_pixels;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrameData:(AVFrame *)frame width:(int)width height:(int)height;

@end

NS_ASSUME_NONNULL_END
