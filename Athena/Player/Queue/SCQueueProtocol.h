//
//  SCQueueProtocol.h
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>

NS_ASSUME_NONNULL_BEGIN

@class SCFrame;
@class SCPacket;

@protocol DemuxToQueueProtocol <NSObject>

- (void)flush;
- (BOOL)packetQueueIsFull;
- (void)enqueue:(SCPacket *)packet;

@end

@protocol DecodeToQueueProtocol <NSObject>

- (void)videoFrameQueueFlush;
- (void)audioFrameQueueFlush;
- (BOOL)videoFrameQueueIsFull;
- (BOOL)audioFrameQueueIsFull;
- (void)enqueueVideoFrames:(NSArray<SCFrame *> *)frames;
- (void)enqueueAudioFrames:(NSArray<SCFrame *> *)frames;

@end

NS_ASSUME_NONNULL_END
