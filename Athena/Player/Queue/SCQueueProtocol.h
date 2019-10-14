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

@protocol DemuxToQueueProtocol <NSObject>

- (void)flush;
- (BOOL)packetQueueIsFull;
- (void)enqueue:(AVPacket)packet;

@end

NS_ASSUME_NONNULL_END
