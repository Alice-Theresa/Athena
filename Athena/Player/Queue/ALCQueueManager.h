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

- (void)packetQueueIsFull;
- (void)flushPacketQueue;
- (void)enqueuePacket:(SCPacket *)packet;
- (SCPacket *)dequeuePacket;

//- (void)flushFrameQueue;
//- (BOOL)frameQueueIsFull:(NSUInteger)index;
//- (void)enqueueFrames:(NSArray<SCFrame *> *)frames;
//- (SCFrame *)dequeueFrameByQueueIndex:(NSNumber *)index;
- (void)videoFrameQueueFlush;
- (void)audioFrameQueueFlush;
- (void)videoFrameQueueIsFull;
- (void)audioFrameQueueIsFull;
- (void)enqueueVideoFrames:(NSArray<SCFrame *> *)frames;
- (void)enqueueAudioFrames:(NSArray<SCFrame *> *)frames;

- (SCFrame *)dequeueVideoFrame;
- (SCFrame *)dequeueAudioFrame;

@end

NS_ASSUME_NONNULL_END
