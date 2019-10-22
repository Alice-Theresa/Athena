//
//  DemuxLayer.m
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import "SCDemuxLayer.h"
#import "SCFormatContext.h"
#import "SCControl.h"
#import "SCPacketQueue.h"

@interface SCDemuxLayer ()

@property (nonatomic, strong) SCFormatContext  *context;
@property (nonatomic, strong) NSOperationQueue *controlQueue;
@property (nonatomic, strong) NSBlockOperation *op;

@property (nonatomic, assign) BOOL             isSeeking;
@property (nonatomic, assign) NSTimeInterval   videoSeekingTime;
@property (nonatomic, assign) SCControlState   controlState;

@end

@implementation SCDemuxLayer

- (instancetype)initWithContext:(SCFormatContext *)context{
    if (self = [super init]) {
        _context = context;
        _controlQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)start {
    self.op = [NSBlockOperation blockOperationWithBlock:^{
        [self readPacket];
    }];
    [self.controlQueue addOperation:self.op];
    self.controlState = SCControlStatePlaying;
}

- (void)resume {
    self.controlState = SCControlStatePlaying;
}

- (void)pause {
    self.controlState = SCControlStatePaused;
}

- (void)close {
    self.controlState = SCControlStateClosed;
    [self.controlQueue cancelAllOperations];
    [self.controlQueue waitUntilAllOperationsAreFinished];
}

- (void)seekingTime:(NSTimeInterval)percentage {
    self.isSeeking = true;
    self.videoSeekingTime = percentage;
}

- (void)readPacket {
    while (true) {
        if (!self.delegate) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if (self.controlState == SCControlStateClosed) {
            break;
        }
        if (self.controlState == SCControlStatePaused || [self.delegate packetQueueIsFull]) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if (self.isSeeking) {
            [self.context seekingTime:self.videoSeekingTime];
            [self.delegate flush];
            self.isSeeking = NO;
            continue;
        }
        AVPacket packet;
        av_init_packet(&packet);
        int result = [self.context readFrame:&packet];
        if (result < 0) {
            NSLog(@"read packet error");
            break;
        } else {
            [self.delegate enqueue:packet];
            
        }
    }
}

@end
