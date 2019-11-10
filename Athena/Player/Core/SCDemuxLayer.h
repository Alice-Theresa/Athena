//
//  DemuxLayer.h
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ALCQueueManager;
@class SCFormatContext;

@interface SCDemuxLayer : NSObject

- (instancetype)initWithContext:(SCFormatContext *)context queueManager:(ALCQueueManager *)manager;

- (void)start;
- (void)resume;
- (void)pause;
- (void)close;
- (void)seekingTime:(NSTimeInterval)time;

@end

NS_ASSUME_NONNULL_END
