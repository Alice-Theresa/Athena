//
//  SCFrameQueue.m
//  Athena
//
//  Created by S.C. on 2019/1/27.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCFrameQueue.h"
#import "SCFrame.h"
#import "SCFrameNode.h"

@interface SCFrameQueue ()

@property (nonatomic, assign, readwrite) NSInteger count;

@property (nonatomic, strong) SCFrameNode *header;
@property (nonatomic, strong) SCFrameNode *tailer;

@end

@implementation SCFrameQueue

- (void)dealloc {
    NSLog(@"Frame Queue dealloc");
}

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (void)enqueueAndSort:(SCFrame *)frame {
    SCFrameNode *node = [[SCFrameNode alloc] initWithFrame:frame];
    if (self.count == 0) {
        self.header = node;
        self.tailer = node;
    } else if (self.tailer.frame.timeStamp > frame.timeStamp) {
        SCFrameNode *search = self.tailer.pre;
        while (search.frame.timeStamp > frame.timeStamp) {
            search = search.pre;
        }
        NSAssert(search.frame.timeStamp < frame.timeStamp, @"err");
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

- (void)enqueueFramesAndSort:(NSArray<SCFrame *> *)frames {
    if (frames.count == 0) {
        return;
    }
    for (SCFrame *frame in frames) {
        [self enqueueAndSort:frame];
    }
}

- (SCFrame *)dequeueFrame {
    SCFrame *frame;
    if (self.count <= 0) {
        return frame;
    }
    frame = self.header.frame;
    SCFrameNode *next = self.header.next;
    next.pre = nil;
    self.header = next;
    self.count--;
    return frame;
}

- (void)flush {
    self.header = nil;
    self.tailer = nil;
    self.count = 0;
}

@end
