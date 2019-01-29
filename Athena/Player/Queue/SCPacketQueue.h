//
//  SCPacketQueue.h
//  Athena
//
//  Created by Theresa on 2019/01/29.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCPacketQueue : NSObject

@property (nonatomic, assign, readonly) NSUInteger packetTotalSize;

- (void)enqueuePacket:(AVPacket)packet;
- (AVPacket)dequeuePacket;
- (void)flush;

@end

NS_ASSUME_NONNULL_END
