//
//  SCDecoderLayer.m
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCDecoderLayer.h"
#import "SCFormatContext.h"
#import "SCControl.h"
#import "SCFrameQueue.h"
#import "SCFrame.h"
#import "SCPacketQueue.h"
#import "SCVideoDecoder.h"
#import "SCAudioDecoder.h"
#import "SCQueueProtocol.h"
#import "SCDemuxLayer.h"
#import "SCPacket.h"
#import "SCVideoFrame.h"
#import "SCPlayerState.h"

@interface SCDecoderLayer () <DemuxToQueueProtocol>

@property (nonatomic, strong) SCPacketQueue *videoPacketQueue;
@property (nonatomic, strong) SCPacketQueue *audioPacketQueue;

@property (nonatomic, assign) BOOL isSeeking;
@property (nonatomic, assign) NSTimeInterval videoSeekingTime;
@property (nonatomic, strong) SCFormatContext *context;
@property (nonatomic, assign) SCPlayerState controlState;

@property (nonatomic, strong) NSOperationQueue *controlQueue;

@property (nonatomic, strong) SCVideoDecoder *videoDecoder;
@property (nonatomic, strong) SCAudioDecoder *audioDecoder;

@end

@implementation SCDecoderLayer

- (instancetype)initWithContext:(SCFormatContext *)context demuxLayer:(SCDemuxLayer *)demuxLayer{
    if (self = [super init]) {
        _context = context;
        _videoPacketQueue = [[SCPacketQueue alloc] init];
        _audioPacketQueue = [[SCPacketQueue alloc] init];

        demuxLayer.delegate = self;
        _videoDecoder = [[SCVideoDecoder alloc] initWithFormatContext:context];
        _audioDecoder = [[SCAudioDecoder alloc] initWithFormatContext:context];
    }
    return self;
}

- (void)start {
    NSInvocationOperation *videoDecodeOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodeVideoFrame) object:nil];
    videoDecodeOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    videoDecodeOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    NSInvocationOperation *audioDecodeOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodeAudioFrame) object:nil];
    audioDecodeOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    audioDecodeOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    self.controlQueue = [[NSOperationQueue alloc] init];
    self.controlQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.controlQueue addOperation:videoDecodeOperation];
    [self.controlQueue addOperation:audioDecodeOperation];
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

- (void)decodeVideoFrame {
    while (self.controlState != SCPlayerStateClosed) {
        if (self.controlState == SCPlayerStatePaused) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if ([self.delegate videoFrameQueueIsFull]) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        @autoreleasepool {
            SCPacket *packet = [self.videoPacketQueue dequeuePacket];
            if (!packet) {
                continue;
            }
            if (packet.core->flags == AV_PKT_FLAG_DISCARD) {
                [self.videoDecoder flush];
                [self.delegate videoFrameQueueFlush];
                SCFrame *frame = [[SCFrame alloc] init];
                frame.type = SCFrameTypeDiscard;
                [self.delegate enqueueVideoFrames:@[frame]];
                continue;
            }
            if (packet.core->data != NULL && packet.core->stream_index >= 0) {
                NSArray<SCFrame *> *frames = [self.videoDecoder decode:packet];
                NSMutableArray *array = [NSMutableArray array];
                for (SCVideoFrame *frame in frames) {
                    [frame fillData];
                    [array addObject:frame];
                }
                [self.delegate enqueueVideoFrames:[array copy]];
            }
        }
    }
}

- (void)decodeAudioFrame {
    while (self.controlState != SCPlayerStateClosed) {
        if (self.controlState == SCPlayerStatePaused) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if ([self.delegate audioFrameQueueIsFull]) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        @autoreleasepool {
            SCPacket *packet = [self.audioPacketQueue dequeuePacket];
            if (!packet) {
                continue;
            }
            if (packet.core->flags == AV_PKT_FLAG_DISCARD) {
                [self.audioDecoder flush];
                [self.delegate audioFrameQueueFlush];
                SCFrame *frame = [[SCFrame alloc] init];
                frame.type = SCFrameTypeDiscard;
                [self.delegate enqueueAudioFrames:@[frame]];
                continue;
            }
            if (packet.core->data != NULL && packet.core->stream_index >= 0) {
                NSArray<SCFrame *> *frames = [self.audioDecoder decode:packet];
                [self.delegate enqueueAudioFrames:frames];
            }
        }
    }
}

# pragma mark - delegate

- (void)enqueue:(SCPacket *)packet {
    if (packet.core->stream_index == self.context.videoIndex) {
        [self.videoPacketQueue enqueuePacket:packet];
    } else if (packet.core->stream_index == self.context.audioIndex) {
        [self.audioPacketQueue enqueuePacket:packet];
    } else if (packet.core->stream_index == self.context.subtitleIndex) {
        NSData *data = [[NSData alloc] initWithBytes:packet.core->data length:packet.core->size];
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@", string);
    }
}

- (void)flush {
    [self.videoPacketQueue flush];
    [self.audioPacketQueue flush];
    [self.videoPacketQueue enqueueDiscardPacket];
    [self.audioPacketQueue enqueueDiscardPacket];
}

- (BOOL)packetQueueIsFull {
    return self.videoPacketQueue.packetTotalSize + self.audioPacketQueue.packetTotalSize > 10 * 1024 * 1024;
}

@end
