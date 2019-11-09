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
#import "ALCQueueManager.h"
#import "SCTrack.h"
#import "SCMetaData.h"

@interface SCDemuxLayer ()

@property (nonatomic, strong) SCFormatContext  *context;
@property (nonatomic, strong) NSOperationQueue *controlQueue;

@property (nonatomic, assign) BOOL             isSeeking;
@property (nonatomic, assign) NSTimeInterval   videoSeekingTime;
@property (nonatomic, assign) SCPlayerState   controlState;
@property (nonatomic, strong) ALCQueueManager *queueManager;

@end

@implementation SCDemuxLayer

- (instancetype)initWithContext:(SCFormatContext *)context queueManager:(ALCQueueManager *)manager {
    if (self = [super init]) {
        _context = context;
        _queueManager = manager;
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
        if (self.controlState == SCPlayerStateClosed) {
            break;
        }
        if (self.controlState == SCPlayerStatePaused || [self.queueManager packetQueueIsFull]) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if (self.isSeeking) {
            [self.context seekingTime:self.videoSeekingTime];
            [self.queueManager flushPacketQueue];
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
            int index = packet.core->stream_index;
            AVStream *stream = self.context.formatContext->streams[index];
            cd.timebase = stream->time_base;
            cd.codecpar = stream->codecpar;
            cd.track    = [[SCTrack alloc] initWithIndex:index
                                                    type:stream->codecpar->codec_type
                                                    meta:[SCMetaData metadataWithAVDictionary:stream->metadata]];
            packet.codecDescriptor = cd;
            packet.timeStamp = (double)packet.core->pts * stream->time_base.num / stream->time_base.den;
            [self.queueManager enqueuePacket:packet];
        }
    }
}

@end
