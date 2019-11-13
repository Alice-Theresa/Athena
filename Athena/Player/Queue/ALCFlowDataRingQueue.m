//
//  ALCFlowDataRingQueue.m
//  Athena
//
//  Created by Skylar on 2019/11/12.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCFlowData.h"
#import "ALCFlowDataRingQueue.h"

@interface ALCFlowDataRingQueue ()

@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic, assign) NSUInteger front;
@property (nonatomic, assign) NSUInteger rear;

@property (nonatomic, assign) NSUInteger computedSize;
@property (nonatomic, assign, readwrite) NSUInteger count;
@property (nonatomic, assign, readwrite) NSUInteger size;

@end

@implementation ALCFlowDataRingQueue

- (instancetype)init {
    if (self = [super init]) {
        _size = pow(2, 3);
        _queue = [NSMutableArray arrayWithCapacity:_size];
        _front = 0;
        _rear = 0;
        _computedSize = _size - 1;
    }
    return self;
}

- (instancetype)initWithLength:(NSUInteger)length {
    if (self = [super init]) {
        _size = pow(2, length);
        _queue = [NSMutableArray arrayWithCapacity:_size];
        _front = 0;
        _rear = 0;
        _computedSize = _size - 1;
    }
    return self;
}

- (BOOL)isFull {
    return ((self.rear + 1) & self.queue.count) == self.front;
}

- (void)enqueue:(NSArray<id<SCFlowData>> *)frames {
    if (frames.count == 0) {
        return;
    }
    for (id<SCFlowData> data in frames) {
        self.queue[self.rear] = data;
        self.count++;
        self.rear = (self.rear + 1) & self.computedSize;
    }
}

- (id<SCFlowData>)dequeue {
    if (self.front == self.rear) {
        return nil;
    }
    id<SCFlowData> data = self.queue[self.front];
    self.front = (self.front + 1) & self.computedSize;
    self.count--;
    return data;
}

- (void)flush {
    [self.queue removeAllObjects];
    self.front = 0;
    self.rear = 0;
    self.computedSize = 0;
}

@end
