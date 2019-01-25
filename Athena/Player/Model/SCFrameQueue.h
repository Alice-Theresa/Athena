//
//  SCFrameQueue.h
//  Athena
//
//  Created by Theresa on 2018/12/28.
//  Copyright © 2018 Theresa. All rights reserved.
//

@class SCFrame;

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCFrameQueue : NSObject

@property (nonatomic, assign, readonly) NSInteger count;

/**
 use for audio frame
 */
- (void)enqueueArray:(NSArray<SCFrame *> *)array;

/**
 use for video frame, sort by pts
 */
- (void)enqueueArrayAndSort:(NSArray<SCFrame *> *)array;

- (SCFrame *)dequeueFrame;

/**
 clear queue and no more receive frames
 */
- (void)flushAndBlock;

/**
 receive frames again
 */
- (void)unblock;

@end

NS_ASSUME_NONNULL_END
