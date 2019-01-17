//
//  SCYUVVideoFrame.h
//  Athena
//
//  Created by Theresa on 2019/01/17.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import "SCFrame.h"

typedef NS_ENUM(int, SGYUVChannel) {
    SGYUVChannelLuma = 0,
    SGYUVChannelChromaB = 1,
    SGYUVChannelChromaR = 2,
    SGYUVChannelCount = 3,
};

NS_ASSUME_NONNULL_BEGIN

@interface SCYUVVideoFrame : SCFrame {
@public;
    UInt8 * channel_pixels[SGYUVChannelCount];
}

- (void)setFrameData:(AVFrame *)frame width:(int)width height:(int)height;

@end

NS_ASSUME_NONNULL_END
