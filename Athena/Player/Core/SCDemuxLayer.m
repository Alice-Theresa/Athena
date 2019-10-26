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
#import "SCPacket.h"
#import "SCCodecDescriptor.h"
#import "SCPlayerState.h"

@interface SCDemuxLayer ()

@property (nonatomic, strong) SCFormatContext  *context;
@property (nonatomic, strong) NSOperationQueue *controlQueue;

@property (nonatomic, assign) BOOL             isSeeking;
@property (nonatomic, assign) NSTimeInterval   videoSeekingTime;
@property (nonatomic, assign) SCPlayerState   controlState;

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
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        [self readPacket];
    }];
    [self.controlQueue addOperation:op];
    self.controlState = SCPlayerStatePlaying;
}

- (void)resume {
    self.controlState = SCPlayerStatePlaying;
}

- (void)pause {
    self.controlState = SCPlayerStatePaused;
}

- (void)close {
    self.controlState = SCPlayerStateClosed;
    [self.controlQueue cancelAllOperations];
    [self.controlQueue waitUntilAllOperationsAreFinished];
}

- (void)seekingTime:(NSTimeInterval)time {
    self.isSeeking = true;
    self.videoSeekingTime = time;
}

- (void)readPacket {
    while (true) {
        if (!self.delegate) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if (self.controlState == SCPlayerStateClosed) {
            break;
        }
        if (self.controlState == SCPlayerStatePaused || [self.delegate packetQueueIsFull]) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if (self.isSeeking) {
            [self.context seekingTime:self.videoSeekingTime];
            [self.delegate flush];
            self.isSeeking = NO;
            continue;
        }
        SCPacket *packet = [[SCPacket alloc] init];
        int result = [self.context readFrame:packet.core];
        if (result < 0) {
            NSLog(@"read packet error");
            break;
        } else {
            SCCodecDescriptor *cd = [[SCCodecDescriptor alloc] init];
            AVStream *stream = self.context.formatContext->streams[packet.core->stream_index];
            cd.timebase = stream->time_base;
            cd.codecpar = stream->codecpar;
            packet.codecDescriptor = cd;
            [self.delegate enqueue:packet];
        }
    }
}

@end
