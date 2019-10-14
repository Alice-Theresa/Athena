//
//  SCDecoderLayer.h
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SCFormatContext;
@class SCPacketQueue;
@class SCFrameQueue;
@class SCDemuxLayer;

@interface SCDecoderLayer : NSObject

- (instancetype)initWithContext:(SCFormatContext *)context
                     demuxLayer:(SCDemuxLayer *)demuxLayer
                          video:(SCFrameQueue *)videoFrameQueue
                          audio:(SCFrameQueue *)audioFrameQueue;
- (void)start;
- (void)resume;
- (void)pause;
- (void)close;

@end

NS_ASSUME_NONNULL_END
