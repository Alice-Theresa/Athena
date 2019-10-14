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

@property (nonatomic, strong) SCPacketQueue *videoPacketQueue;
@property (nonatomic, strong) SCPacketQueue *audioPacketQueue;

@property (nonatomic, assign) BOOL isSeeking;
@property (nonatomic, assign) NSTimeInterval videoSeekingTime;
@property (nonatomic, strong) SCFormatContext *context;
@property (nonatomic, assign) SCControlState controlState;

@property (nonatomic, strong) NSOperationQueue *controlQueue;

@end

@implementation SCDemuxLayer

- (instancetype)initWithContext:(SCFormatContext *)context
                          video:(SCPacketQueue *)videoPacketQueue
                          audio:(SCPacketQueue *)audioPacketQueue {
    if (self = [super init]) {
        _context = context;
        _videoPacketQueue = videoPacketQueue;
        _audioPacketQueue = audioPacketQueue;
    }
    return self;
}

- (void)start {
    NSInvocationOperation *readPacketOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(readPacket) object:nil];
    readPacketOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    readPacketOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    self.controlQueue = [[NSOperationQueue alloc] init];
    self.controlQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.controlQueue addOperation:readPacketOperation];
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
    BOOL finished = NO;
    while (!finished) {
        if (self.controlState == SCControlStateClosed) {
            break;
        }
        if (self.controlState == SCControlStatePaused) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if (self.videoPacketQueue.packetTotalSize + self.audioPacketQueue.packetTotalSize > 10 * 1024 * 1024) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if (self.isSeeking) {
            [self.context seekingTime:self.videoSeekingTime];
            [self.videoPacketQueue flush];
            [self.audioPacketQueue flush];
            [self.videoPacketQueue enqueueDiscardPacket];
            [self.audioPacketQueue enqueueDiscardPacket];
            self.isSeeking = NO;
            continue;
        }
        AVPacket packet;
        av_init_packet(&packet);
        int result = [self.context readFrame:&packet];
        if (result < 0) {
            NSLog(@"read packet error");
            finished = YES;
            break;
        } else {
            if (packet.stream_index == self.context.videoIndex) {
                [self.videoPacketQueue enqueuePacket:packet];
            } else if (packet.stream_index == self.context.audioIndex) {
                [self.audioPacketQueue enqueuePacket:packet];
            } else if (packet.stream_index == self.context.subtitleIndex) {
                NSData *data = [[NSData alloc] initWithBytes:packet.data length:packet.size];
                NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"%@", string);
            }
        }
    }
}

@end
