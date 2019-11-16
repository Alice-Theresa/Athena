//
//  SCCodecContext.h
//  Athena
//
//  Created by Skylar on 2019/10/26.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCFlowData.h"

NS_ASSUME_NONNULL_BEGIN

@class SCPacket;

@interface SCCodecContext : NSObject

@property (nonatomic, assign, readonly) AVCodecContext *core;

- (instancetype)initWithTimebase:(AVRational)timebase codecpar:(AVCodecParameters *)codecpar frameClass:(Class)frameClass;
- (NSArray<id<SCFrame>> *)decode:(SCPacket *)packet;
- (void)flush;

@end

NS_ASSUME_NONNULL_END
