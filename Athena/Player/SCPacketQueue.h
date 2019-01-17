//
//  PacketQueue.h
//  Athena
//
//  Created by Theresa on 2018/12/27.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCPacketQueue : NSObject

+ (instancetype)shared;
- (void)putPacket:(AVPacket)packet;
- (AVPacket)getPacket;
- (void)flush;

@end

NS_ASSUME_NONNULL_END
