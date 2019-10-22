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

@interface SCDecoderLayer () <DemuxToQueueProtocol>

@property (nonatomic, strong) SCPacketQueue *videoPacketQueue;
@property (nonatomic, strong) SCPacketQueue *audioPacketQueue;
@property (nonatomic, strong) SCFrameQueue  *videoFrameQueue;
@property (nonatomic, strong) SCFrameQueue  *audioFrameQueue;

@property (nonatomic, assign) BOOL isSeeking;
@property (nonatomic, assign) NSTimeInterval videoSeekingTime;
@property (nonatomic, strong) SCFormatContext *context;
@property (nonatomic, assign) SCControlState controlState;

@property (nonatomic, strong) NSOperationQueue *controlQueue;

@property (nonatomic, strong) SCVideoDecoder *videoDecoder;
@property (nonatomic, strong) SCAudioDecoder *audioDecoder;

@end

@implementation SCDecoderLayer

- (instancetype)initWithContext:(SCFormatContext *)context
                          demuxLayer:(SCDemuxLayer *)demuxLayer
                          video:(SCFrameQueue *)videoFrameQueue
                          audio:(SCFrameQueue *)audioFrameQueue {
    if (self = [super init]) {
        _context = context;
        _videoPacketQueue = [[SCPacketQueue alloc] init];
        _audioPacketQueue = [[SCPacketQueue alloc] init];
        _videoFrameQueue = videoFrameQueue;
        _audioFrameQueue = audioFrameQueue;
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


- (void)decodeVideoFrame {
    while (self.controlState != SCControlStateClosed) {
        if (self.controlState == SCControlStatePaused) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if (self.videoFrameQueue.count > 10) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        @autoreleasepool {
            AVPacket packet = [self.videoPacketQueue dequeuePacket];
            if (packet.flags == AV_PKT_FLAG_DISCARD) {
                avcodec_flush_buffers(self.context.videoCodecContext);
                [self.videoFrameQueue flush];
                SCFrame *frame = [[SCFrame alloc] init];
                frame.duration = -1;
                [self.videoFrameQueue enqueueFramesAndSort:@[frame]];
                av_packet_unref(&packet);
                continue;
            }
            if (packet.data != NULL && packet.stream_index >= 0) {
                NSArray<SCFrame *> *frames = [self.videoDecoder decode:packet];
                [self.videoFrameQueue enqueueFramesAndSort:frames];
            }
        }
    }
}

- (void)decodeAudioFrame {
    while (self.controlState != SCControlStateClosed) {
        if (self.controlState == SCControlStatePaused) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if (self.audioFrameQueue.count > 10) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        @autoreleasepool {
            AVPacket packet = [self.audioPacketQueue dequeuePacket];
            if (packet.flags == AV_PKT_FLAG_DISCARD) {
                avcodec_flush_buffers(self.context.audioCodecContext);
                [self.audioFrameQueue flush];
                SCFrame *frame = [[SCFrame alloc] init];
                frame.duration = -1;
                [self.audioFrameQueue enqueueFramesAndSort:@[frame]];
                av_packet_unref(&packet);
                continue;
            }
            if (packet.data != NULL && packet.stream_index >= 0) {
                NSArray<SCFrame *> *frames = [self.audioDecoder decode:packet];
                [self.audioFrameQueue enqueueFramesAndSort:frames];
            }
        }
    }
}

# pragma mark - delegate

- (void)enqueue:(AVPacket)packet {
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
