//
//  ALCFlowDataQueue.h
//  Athena
//
//  Created by Skylar on 2019/11/10.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCFlowData.h"
#import "SCTrack.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALCFlowDataQueue : NSObject

@property (nonatomic, assign) SCTrackType type;
@property (nonatomic, assign, readonly) NSUInteger length;
@property (nonatomic, assign, readonly) NSUInteger size;

- (void)enqueue:(NSArray<SCFlowData *> *)frames;

- (SCFlowData *)dequeue;

- (void)flush;

@end

NS_ASSUME_NONNULL_END
