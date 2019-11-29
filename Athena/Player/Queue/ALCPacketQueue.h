//
//  ALCPacketQueue.h
//  Athena
//
//  Created by skylar on 2019/11/29.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALCTrack.h"
#import "ALCFlowData.h"

@class ALCFormatContext;

NS_ASSUME_NONNULL_BEGIN

@interface ALCPacketQueue : NSObject

- (instancetype)initWithContext:(ALCFormatContext *)context;

- (void)packetQueueIsFull;
- (void)flushPacketQueue;
- (void)enqueuePacket:(ALCFlowData *)packet;
- (ALCFlowData *)dequeuePacket;
- (void)destory;

@end

NS_ASSUME_NONNULL_END
