//
//  ALCFlowDataRingQueue.h
//  Athena
//
//  Created by Skylar on 2019/11/12.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALCFlowDataRingQueue : NSObject

@property (nonatomic, assign, readonly) NSUInteger count;
@property (nonatomic, assign, readonly) NSUInteger size;

- (instancetype)initWithLength:(NSUInteger)length;

- (BOOL)isFull;

- (void)enqueue:(NSArray<id<SCFlowData>> *)frames;

- (id<SCFlowData>)dequeue;

- (void)flush;

@end

NS_ASSUME_NONNULL_END
