//
//  ALCFrameQueue.m
//  Athena
//
//  Created by skylar on 2019/11/29.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "ALCFrameQueue.h"
#import "ALCFlowDataQueue.h"

#define VideoFrameQueueMaxSize 3
#define AudioFrameQueueMaxSize 5

@interface ALCFrameQueue ()

@property (nonatomic, strong) NSCondition *frameWakeup;
@property (nonatomic, strong) ALCFlowDataQueue *videoFrameQueue;
@property (nonatomic, strong) ALCFlowDataQueue *audioFrameQueue;

@end

@implementation ALCFrameQueue

- (void)destory {
    [self.frameWakeup lock];
    [self.frameWakeup broadcast];
    [self.frameWakeup unlock];
}

- (instancetype)init {
    if (self = [super init]) {
        _frameWakeup  = [[NSCondition alloc] init];
        _videoFrameQueue = [[ALCFlowDataQueue alloc] init];
        _audioFrameQueue = [[ALCFlowDataQueue alloc] init];
    }
    return self;
}

- (void)flushFrameQueue:(SCTrackType)type {
    [self.frameWakeup lock];
    if (type == SCTrackTypeVideo) {
        [self.videoFrameQueue flush];
    } else if (type == SCTrackTypeAudio) {
        [self.audioFrameQueue flush];
    }
    [self.frameWakeup unlock];
}

- (void)frameQueueIsFull:(SCTrackType)type {
    [self.frameWakeup lock];
    BOOL isFull = NO;
    if (type == SCTrackTypeVideo) {
        isFull = self.videoFrameQueue.length > VideoFrameQueueMaxSize;
    } else if (type == SCTrackTypeAudio) {
        isFull = self.audioFrameQueue.length > AudioFrameQueueMaxSize;
    }
    if (isFull) {
        [self.frameWakeup wait];
    }
    [self.frameWakeup unlock];
}

- (void)enqueueFrames:(NSArray<SCFlowData *> *)frames {
    [self.frameWakeup lock];
    if (frames.firstObject.mediaType == SCMediaTypeVideo) {
        [self.videoFrameQueue enqueue:frames];
    } else if (frames.firstObject.mediaType == SCMediaTypeAudio) {
        [self.audioFrameQueue enqueue:frames];
    }
    [self.frameWakeup unlock];
}

- (SCFlowData *)dequeueFrameByQueueIndex:(SCTrackType)type {
    [self.frameWakeup lock];
    SCFlowData * frame;
    BOOL isFull = NO;
    if (type == SCTrackTypeVideo) {
        frame = [self.videoFrameQueue dequeue];
        isFull = self.videoFrameQueue.length > VideoFrameQueueMaxSize;
    } else if (type == SCTrackTypeAudio) {
        frame = [self.audioFrameQueue dequeue];
        isFull = self.audioFrameQueue.length > AudioFrameQueueMaxSize;
    }
    if (!isFull) {
        [self.frameWakeup signal];
    }
    [self.frameWakeup unlock];
    return frame;
}

@end
