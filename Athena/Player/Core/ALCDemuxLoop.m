//
//  DemuxLayer.m
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import "ALCDemuxLoop.h"
#import "ALCFormatContext.h"
#import "ALCControl.h"
#import "ALCPacket.h"
#import "ALCCodecDescriptor.h"
#import "ALCPlayerState.h"
#import "ALCPacketQueue.h"
#import "ALCTrack.h"
#import "ALCMetaData.h"

@interface ALCDemuxLoop ()

@property (nonatomic, strong) ALCFormatContext  *context;
@property (nonatomic, strong) NSOperationQueue *controlQueue;

@property (nonatomic, assign) BOOL             isSeeking;
@property (nonatomic, assign) NSTimeInterval   videoSeekingTime;
@property (nonatomic, assign) ALCPlayerState   controlState;
@property (nonatomic, strong) ALCPacketQueue *packetQueue;

@property (nonatomic, strong) NSCondition *wakeup;

@end

@implementation ALCDemuxLoop

- (void)dealloc {
    NSLog(@"demux dealloc");
}

- (instancetype)initWithContext:(ALCFormatContext *)context packetQueue:(ALCPacketQueue *)packetQueue {
    if (self = [super init]) {
        _context = context;
        _packetQueue = packetQueue;
        _controlQueue = [[NSOperationQueue alloc] init];
        _wakeup = [[NSCondition alloc] init];
    }
    return self;
}

- (void)start {
    NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(readPacket) object:nil];
    [self.controlQueue addOperation:op];
    self.controlState = ALCPlayerStatePlaying;
}

- (void)resume {
    self.controlState = ALCPlayerStatePlaying;
    [self.wakeup signal];
}

- (void)pause {
    self.controlState = ALCPlayerStatePaused;
}

- (void)close {
    self.controlState = ALCPlayerStateClosed;
    [self.controlQueue cancelAllOperations];
    [self.controlQueue waitUntilAllOperationsAreFinished];
}

- (void)seekingTime:(NSTimeInterval)time {
    self.isSeeking = true;
    self.videoSeekingTime = time;
    [self.wakeup signal];
}

- (void)readPacket {
    while (true) {
        if (self.controlState == ALCPlayerStateClosed) {
            break;
        }
        [self.packetQueue packetQueueIsFull];
        if (self.controlState == ALCPlayerStatePaused) {
            [self.wakeup lock];
            [self.wakeup wait];
            [self.wakeup unlock];
            continue;
        }
        if (self.isSeeking) {
            [self.context seekingTime:self.videoSeekingTime];
            [self.packetQueue flushPacketQueue];
            self.isSeeking = NO;
            continue;
        }
        ALCPacket *packet = [[ALCPacket alloc] init];
        int result = [self.context readFrame:packet.core];
        if (result < 0) {
            NSLog(@"read packet error");
            [self.wakeup wait];
        } else {
            int index = packet.core->stream_index;
            AVStream *stream = self.context.core->streams[index];
            ALCCodecDescriptor *cd = [[ALCCodecDescriptor alloc] init];
            cd.timebase = stream->time_base;
            cd.codecpar = stream->codecpar;
            cd.track    = [[ALCTrack alloc] initWithIndex:index
                                                    type:(int)stream->codecpar->codec_type
                                                    meta:[ALCMetaData metadataWithAVDictionary:stream->metadata]];
            packet.codecDescriptor = cd;
            packet.timeStamp = (double)packet.core->pts * stream->time_base.num / stream->time_base.den;
//            packet.duration
            packet.size = packet.core->size;
            packet.flowDataType = ALCFlowDataTypePacket;
//            packet.mediaType =
            [self.packetQueue enqueuePacket:packet];
        }
    }
}

@end
