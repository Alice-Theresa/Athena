//
//  ALCQueueManager.h
//  Athena
//
//  Created by Skylar on 2019/11/9.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCPacket;
@class SCFrame;
@class SCPacketQueue;
@class SCFormatContext;

NS_ASSUME_NONNULL_BEGIN

@interface ALCQueueManager : NSObject

- (instancetype)initWithContext:(SCFormatContext *)context;

- (BOOL)packetQueueIsFull;
- (void)flushPacketQueue;
- (void)enqueuePacket:(SCPacket *)packet;
- (SCPacket *)dequeuePacket;

- (void)flushFrameQueue;
- (BOOL)frameQueueIsFull;
- (void)enqueueFrames:(NSArray<SCFrame *> *)frames;
- (SCFrame *)dequeueFrameByQueueIndex:(NSNumber *)index;

@end

NS_ASSUME_NONNULL_END
