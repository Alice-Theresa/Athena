//
//  SCPacketQueue.h
//  Athena
//
//  Created by Theresa on 2019/01/29.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import <Foundation/Foundation.h>
#import "SCTrack.h"

@class SCPacket;

NS_ASSUME_NONNULL_BEGIN

@interface SCPacketQueue : NSObject

@property (nonatomic, assign) SCTrackType type;
@property (nonatomic, assign, readonly) NSUInteger packetTotalSize;

- (void)enqueueDiscardPacket;
- (void)enqueuePacket:(SCPacket *)packet;
- (SCPacket *)dequeuePacket;
- (void)flush;

@end

NS_ASSUME_NONNULL_END
