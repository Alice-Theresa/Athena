//
//  DemuxLayer.h
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCQueueProtocol.h"
NS_ASSUME_NONNULL_BEGIN

@class SCFormatContext;
@class SCPacketQueue;

@interface SCDemuxLayer : NSObject

@property (nonatomic, weak  ) id<DemuxToQueueProtocol> delegate;

- (instancetype)initWithContext:(SCFormatContext *)context;

- (void)start;
- (void)resume;
- (void)pause;
- (void)close;
- (void)seekingTime:(NSTimeInterval)percentage;

@end

NS_ASSUME_NONNULL_END
