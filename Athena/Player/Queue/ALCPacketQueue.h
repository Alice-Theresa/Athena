//
//  ALCPacketQueue.h
//  Athena
//
//  Created by skylar on 2019/11/29.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCTrack.h"
#import "SCFlowData.h"

@class ALCFormatContext;

NS_ASSUME_NONNULL_BEGIN

@interface ALCPacketQueue : NSObject

- (instancetype)initWithContext:(ALCFormatContext *)context;

- (void)packetQueueIsFull;
- (void)flushPacketQueue;
- (void)enqueuePacket:(SCFlowData *)packet;
- (SCFlowData *)dequeuePacket;
- (void)destory;

@end

NS_ASSUME_NONNULL_END
