//
//  SCFrameQueue.h
//  Athena
//
//  Created by S.C. on 2019/1/27.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCFrame;

NS_ASSUME_NONNULL_BEGIN

@interface SCFrameQueue : NSObject

@property (nonatomic, assign, readonly) NSInteger count;

- (void)enqueueFramesAndSort:(NSArray<SCFrame *> *)frames;

- (SCFrame *)dequeueFrame;

- (void)flush;

@end

NS_ASSUME_NONNULL_END
