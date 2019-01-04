//
//  SCVideoFrameQueue.m
//  Athena
//
//  Created by Theresa on 2018/12/28.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import "SCVideoFrameQueue.h"
#import "SCVideoFrame.h"

@interface SCVideoFrameQueue ()

@property (nonatomic, assign, readwrite) NSInteger count;
@property (nonatomic, strong) NSCondition *condition;
@property (nonatomic, strong) NSMutableArray <SCVideoFrame *> *frames;

@end

@implementation SCVideoFrameQueue

+ (instancetype)shared {
    static SCVideoFrameQueue *queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[SCVideoFrameQueue alloc] init];
    });
    return queue;
}

- (instancetype)init {
    if (self = [super init]) {
        self.frames = [NSMutableArray array];
        self.condition = [[NSCondition alloc] init];
    }
    return self;
}

- (void)putFrame:(SCVideoFrame *)frame {
    if (!frame) {
        return;
    }
    [self.condition lock];
    BOOL added = NO;
    if (self.frames.count > 0) {
        for (int i = (int)self.frames.count - 1; i >= 0; i--) {
            SCVideoFrame *obj = [self.frames objectAtIndex:i];
            if (frame.position > obj.position) {
                [self.frames insertObject:frame atIndex:i + 1];
                added = YES;
                break;
            }
        }
    }
    if (!added) {
        [self.frames addObject:frame];
        added = YES;
    }
    self.count++;
    [self.condition unlock];
}

- (SCVideoFrame *)getFrame {
    [self.condition lock];
    SCVideoFrame *frame;
    if (self.frames.count <= 0) {
        [self.condition unlock];
        return frame;
    }
    frame = self.frames.firstObject;
    [self.frames removeObjectAtIndex:0];
    [self.condition unlock];
    self.count--;
    return frame;
}

@end
