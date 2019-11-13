//
//  ALCQueueManager.m
//  Athena
//
//  Created by Skylar on 2019/11/9.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "ALCQueueManager.h"
#import "SCPacketQueue.h"
#import "SCPacket.h"
#import "SCTrack.h"
#import "SCFormatContext.h"
#import "ALCFlowDataRingQueue.h"

#import "ALCFlowDataQueue.h"
#import "SCCodecDescriptor.h"

@interface ALCQueueManager ()

@property (nonatomic, strong) NSCondition *packetWakeup;
@property (nonatomic, strong) NSCondition *frameWakeup;

@property (nonatomic, copy  ) NSDictionary<NSString *, SCPacketQueue *> *packetsQueue;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *timeStamps;

@property (nonatomic, strong) ALCFlowDataRingQueue *videoFrameQueue;
@property (nonatomic, strong) ALCFlowDataRingQueue *audioFrameQueue;

@end

@implementation ALCQueueManager

- (instancetype)initWithContext:(SCFormatContext *)context {
    if (self = [super init]) {
        _packetWakeup = [[NSCondition alloc] init];
        _frameWakeup  = [[NSCondition alloc] init];

        _packetsQueue    = [NSMutableDictionary dictionary];
        _timeStamps      = [NSMutableDictionary dictionary];
        _videoFrameQueue = [[ALCFlowDataRingQueue alloc] initWithLength:2];
        _audioFrameQueue = [[ALCFlowDataRingQueue alloc] initWithLength:4];
        for (SCTrack *track in context.tracks) {
            SCPacketQueue *queue = [[SCPacketQueue alloc] init];
            queue.type = track.type;
            [_packetsQueue setValue:queue forKey:[NSString stringWithFormat:@"%d", track.index]];
        }
    }
    return self;
}

#pragma mark - packet queue

- (void)packetQueueIsFull {
    [self.packetWakeup lock];
    int total = 0;
    for (NSString *key in self.packetsQueue) {
        total += self.packetsQueue[key].packetTotalSize;
    }
    BOOL isFull = total > 10 * 1024 * 1024;
    if (isFull) {
        [self.packetWakeup wait];
    }
    [self.packetWakeup unlock];
}

- (void)flushPacketQueue {
    [self.packetWakeup lock];
    for (NSString *key in self.packetsQueue) {
        [self.packetsQueue[key] flush];

        SCCodecDescriptor *cd = [[SCCodecDescriptor alloc] init];
        cd.track = [[SCTrack alloc] initWithIndex:-1 type:self.packetsQueue[key].type meta:NULL];
        SCPacket *packet = [[SCPacket alloc] init];
        packet.core->flags = AV_PKT_FLAG_DISCARD;
        packet.codecDescriptor = cd;
        [self.packetsQueue[key] enqueuePacket:packet];
    }
    [self.timeStamps removeAllObjects];
    [self.packetWakeup unlock];
}

- (void)enqueuePacket:(SCPacket *)packet {
    [self.packetWakeup lock];
    SCPacketQueue *queue = [self.packetsQueue valueForKey:[NSString stringWithFormat:@"%d", packet.core->stream_index]];
    [queue enqueuePacket:packet];
    [self.packetWakeup unlock];
}

- (SCPacket *)dequeuePacket {
    [self.packetWakeup lock];
    int streamIndex = -1;
    double min = DBL_MAX;
    for (NSString *key in self.packetsQueue) {
       if (self.packetsQueue[key].packetTotalSize == 0) {
           continue;
       }
       NSNumber *time = self.timeStamps[key];
       if (!time) {
           streamIndex = [key intValue];
           break;
       }
       double timestamp = [self.timeStamps[key] doubleValue];
       if (timestamp < min) {
           min = timestamp;
           streamIndex = [key intValue];
           continue;
       }
    }
    if (streamIndex == -1) {
        [self.packetWakeup unlock];
        return nil;
    }
    SCPacket *packet = [self.packetsQueue[@(streamIndex).stringValue] dequeuePacket];
    [self.timeStamps setValue:@(packet.timeStamp) forKey:@(streamIndex).stringValue];
    int total = 0;
    for (NSString *key in self.packetsQueue) {
        total += self.packetsQueue[key].packetTotalSize;
    }
    BOOL isFull = total > 10 * 1024 * 1024;
    if (!isFull) {
        [self.packetWakeup signal];
    }
    [self.packetWakeup unlock];
    return packet;
}

#pragma mark -

- (void)videoFrameQueueFlush {
    [self.frameWakeup lock];
    [self.videoFrameQueue flush];
    [self.frameWakeup unlock];
}

- (void)audioFrameQueueFlush {
    [self.frameWakeup lock];
    [self.audioFrameQueue flush];
    [self.frameWakeup unlock];
}

- (void)videoFrameQueueIsFull {
    [self.frameWakeup lock];
    BOOL isFull = self.videoFrameQueue.count > 5;
    if (isFull) {
        [self.frameWakeup wait];
    }
    [self.frameWakeup unlock];
}

- (void)audioFrameQueueIsFull {
    [self.frameWakeup lock];
    BOOL isFull = self.audioFrameQueue.count > 5;
    if (isFull) {
        [self.frameWakeup wait];
    }
    [self.frameWakeup unlock];
}

- (void)enqueueAudioFrames:(nonnull NSArray<SCFrame *> *)frames {
    [self.frameWakeup lock];
    [self.audioFrameQueue enqueue:frames];
    [self.frameWakeup unlock];
}

- (void)enqueueVideoFrames:(nonnull NSArray<SCFrame *> *)frames {
    [self.frameWakeup lock];
    [self.videoFrameQueue enqueue:frames];
    [self.frameWakeup unlock];
}

- (SCFrame *)dequeueVideoFrame {
    [self.frameWakeup lock];
    SCFrame *frame = [self.videoFrameQueue dequeue];
    BOOL isFull = self.videoFrameQueue.count > 5;
    if (!isFull) {
        [self.frameWakeup signal];
    }
    [self.frameWakeup unlock];
    return frame;
}

- (SCFrame *)dequeueAudioFrame {
    [self.frameWakeup lock];
    SCFrame *frame = [self.audioFrameQueue dequeue];
    BOOL isFull = self.audioFrameQueue.count > 5;
    if (!isFull) {
        [self.frameWakeup signal];
    }
    [self.frameWakeup unlock];
    return frame;
}

@end
