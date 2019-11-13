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
@property (nonatomic, assign) NSUInteger usedSize;

@end

@implementation ALCFlowDataRingQueue

- (instancetype)init {
    if (self = [super init]) {
        _queue = [NSMutableArray arrayWithCapacity:pow(2, 3)];
        _front = 0;
        _rear = 0;
        _usedSize = 0;
    }
    return self;
}

- (instancetype)initWithLength:(NSUInteger)length {
    if (self = [super init]) {
        _queue = [NSMutableArray arrayWithCapacity:pow(2, length)];
        _front = 0;
        _rear = 0;
        _usedSize = 0;
    }
    return self;
}

- (BOOL)isFull {
    return ((self.rear + 1) & self.queue.count) == self.front;
}

- (void)enqueue:(id<SCFlowData>)data {
    self.queue[self.rear] = data;
    self.usedSize++;
    self.rear = (self.rear + 1) & self.queue.count;
}


- (id<SCFlowData>)dequeue {
    if (self.front == self.rear) {
        return nil;
    }
    id<SCFlowData> data = self.queue[self.front];
    self.front = (self.front + 1) & self.queue.count;
    self.usedSize--;
    return data;
}

- (void)flush {
    [self.queue removeAllObjects];
    self.front = 0;
    self.rear = 0;
    self.usedSize = 0;
}

@end
