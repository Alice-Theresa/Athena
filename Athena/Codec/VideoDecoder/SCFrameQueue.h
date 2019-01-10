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
- (void)enqueue:(SCFrame *)frame;

/**
 use for video frame, sort by pts
 */
- (void)enqueueAndSort:(SCFrame *)frame;

- (SCFrame *)dequeueFrame;

- (void)flush;

@end

NS_ASSUME_NONNULL_END
