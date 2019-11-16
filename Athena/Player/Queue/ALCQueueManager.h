//
//  ALCQueueManager.h
//  Athena
//
//  Created by Skylar on 2019/11/9.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCTrack.h"
#import "SCFlowData.h"

@class SCFormatContext;

NS_ASSUME_NONNULL_BEGIN

@interface ALCQueueManager : NSObject

- (instancetype)initWithContext:(SCFormatContext *)context;

- (void)packetQueueIsFull;
- (void)flushPacketQueue;
- (void)enqueuePacket:(id<SCFlowData>)packet;
- (id<SCFlowData>)dequeuePacket;

- (void)flushFrameQueue:(SCTrackType)type;
- (void)frameQueueIsFull:(SCTrackType)type;
- (void)enqueueFrames:(NSArray<id<SCFlowData>> *)frames;
- (id<SCFlowData>)dequeueFrameByQueueIndex:(SCTrackType)type;

@end

NS_ASSUME_NONNULL_END
