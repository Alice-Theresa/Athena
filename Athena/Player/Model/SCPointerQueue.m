//
//  SCPointerQueue.m
//  Athena
//
//  Created by S.C. on 2019/1/27.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCPointerQueue.h"
#import "SCFrame.h"
#import "SCNode.h"

@interface SCPointerQueue ()

@property (nonatomic, assign) BOOL isBlock;
@property (nonatomic, assign, readwrite) NSInteger count;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@property (nonatomic, strong) SCNode *header;
@property (nonatomic, strong) SCNode *tailer;

@end

@implementation SCPointerQueue

- (void)dealloc {
    NSLog(@"Frame Queue dealloc");
}

- (instancetype)init {
    if (self = [super init]) {
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)enqueueAndSort:(SCFrame *)frame {
    SCNode *node = [[SCNode alloc] initWithFrame:frame];
    if (self.count == 0) {
        self.header = node;
        self.tailer = node;
    } else if (self.tailer.frame.position > frame.position) {
        SCNode *search = self.tailer.pre;
        while (search.frame.position > frame.position) {
            search = search.pre;
        }
        NSAssert(search.frame.position < frame.position, @"err");
        node.next = search.next;
        search.next.pre = node;
        node.pre = search;
        search.next = node;
    } else {
        self.tailer.next = node;
        node.pre = self.tailer;
        self.tailer = node;
    }
    self.count++;
}

- (void)enqueueArrayAndSort:(NSArray<SCFrame *> *)array {
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
    if (self.count <= 0) {
        dispatch_semaphore_signal(self.semaphore);
        return frame;
    }
    frame = self.header.frame;
    SCNode *next = self.header.next;
    next.pre = nil;
    self.header = next;
    self.count--;
    dispatch_semaphore_signal(self.semaphore);
    return frame;
}

- (void)flushAndBlock {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    self.header = nil;
    self.tailer = nil;
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
