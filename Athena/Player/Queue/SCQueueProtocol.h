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

@protocol DemuxToQueueProtocol <NSObject>

- (void)flush;
- (BOOL)packetQueueIsFull;
- (void)enqueue:(AVPacket)packet;

@end

@protocol DecodeToQueueProtocol <NSObject>

- (void)flush;
- (BOOL)frameQueueIsFull;
- (void)enqueueFramesAndSort:(NSArray<SCFrame *> *)frames;

@end

NS_ASSUME_NONNULL_END
