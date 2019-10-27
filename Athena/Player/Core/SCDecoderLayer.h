//
//  SCDecoderLayer.h
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCQueueProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class SCFormatContext;
@class SCPacketQueue;
@class SCFrameQueue;
@class SCDemuxLayer;

@interface SCDecoderLayer : NSObject

@property (nonatomic, weak  ) id<DecodeToQueueProtocol> delegate;

- (instancetype)initWithContext:(SCFormatContext *)context demuxLayer:(SCDemuxLayer *)demuxLayer;
- (void)start;
- (void)resume;
- (void)pause;
- (void)close;

@end

NS_ASSUME_NONNULL_END
