//
//  SCFrameQueue.m
//  Athena
//
//  Created by Theresa on 2018/12/28.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import "SCFrameQueue.h"
#import "SCNV12VideoFrame.h"


@interface SCFrameQueue ()

@property (nonatomic, assign) BOOL isBlock;
@property (nonatomic, assign, readwrite) NSInteger count;
@property (nonatomic, strong) NSMutableArray <SCFrame *> *frames;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation SCFrameQueue

- (void)dealloc {
    NSLog(@"Frame Queue dealloc");
}

- (instancetype)init {
    if (self = [super init]) {
        _frames = [NSMutableArray array];
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)enqueueArray:(NSArray<SCFrame *> *)array {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    if (array.count == 0 || self.isBlock) {
        dispatch_semaphore_signal(self.semaphore);
        return;
    }
    [self.frames addObjectsFromArray:array];
    self.count += array.count;
    dispatch_semaphore_signal(self.semaphore);
}

- (void)enqueueAndSort:(SCFrame *)frame {
    BOOL added = NO;
    if (self.frames.count > 0) {
        for (int i = (int)self.frames.count - 1; i >= 0; i--) {
            SCFrame *obj = [self.frames objectAtIndex:i];
            if (frame.position > obj.position) {
                [self.frames insertObject:frame atIndex:i + 1];
                added = YES;
                break;
            }
        }
    }
    if (!added) {
        [self.frames addObject:frame];
    }
    self.count++;
}

- (void)enqueueFramesAndSort:(NSArray<SCFrame *> *)array {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    if (array.count == 0 || self.isBlock) {
        dispatch_semaphore_signal(self.semaphore);
        return;
    }
    for (SCFrame *frame in array) {
        [self enqueueAndSort:frame];
    }
    dispatch_semaphore_signal(self.semaphore);
}

- (SCFrame *)dequeueFrame {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    SCFrame *frame;
    if (self.frames.count <= 0) {
        dispatch_semaphore_signal(self.semaphore);
        return frame;
    }
    frame = self.frames.firstObject;
    [self.frames removeObjectAtIndex:0];
    self.count--;
    dispatch_semaphore_signal(self.semaphore);
    return frame;
}

- (void)flushAndBlock {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    [self.frames removeAllObjects];
    self.count = 0;
    self.isBlock = YES;
    dispatch_semaphore_signal(self.semaphore);
}

- (void)unblock {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    self.isBlock = NO;
    dispatch_semaphore_signal(self.semaphore);
}

@end
