//
//  ALCQueueManager.m
//  Athena
//
//  Created by Skylar on 2019/11/9.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "ALCQueueManager.h"
#import "SCPacket.h"
#import "SCTrack.h"
#import "ALCFormatContext.h"
#import "ALCFlowDataRingQueue.h"

#import "ALCFlowDataQueue.h"
#import "SCCodecDescriptor.h"

#define PacketTotalMaxsize 10 * 1024 * 1024
#define VideoFrameQueueMaxSize 3
#define AudioFrameQueueMaxSize 5

@interface ALCQueueManager ()

@property (nonatomic, strong) NSCondition *packetWakeup;
@property (nonatomic, strong) NSCondition *frameWakeup;

@property (nonatomic, copy  ) NSDictionary<NSString *, ALCFlowDataQueue *> *packetsQueue;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *timeStamps;

@property (nonatomic, strong) ALCFlowDataQueue *videoFrameQueue;
@property (nonatomic, strong) ALCFlowDataQueue *audioFrameQueue;

@end

@implementation ALCQueueManager

- (instancetype)initWithContext:(ALCFormatContext *)context {
    if (self = [super init]) {
        _packetWakeup = [[NSCondition alloc] init];
        _frameWakeup  = [[NSCondition alloc] init];

        _packetsQueue    = [NSMutableDictionary dictionary];
        _timeStamps      = [NSMutableDictionary dictionary];
        _videoFrameQueue = [[ALCFlowDataQueue alloc] init];
        _audioFrameQueue = [[ALCFlowDataQueue alloc] init];
        for (SCTrack *track in context.tracks) {
            ALCFlowDataQueue *queue = [[ALCFlowDataQueue alloc] init];
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
    int length = 0;
    for (NSString *key in self.packetsQueue) {
        total += self.packetsQueue[key].size;
        length += self.packetsQueue[key].length;
    }
    BOOL isFull = total > PacketTotalMaxsize || length > 1000;
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
        packet.flowDataType = SCFlowDataTypeDiscard;
        packet.codecDescriptor = cd;
        [self.packetsQueue[key] enqueue:@[packet]];
    }
    [self.timeStamps removeAllObjects];
    [self.packetWakeup unlock];
}

- (void)enqueuePacket:(SCFlowData *)packet {
    [self.packetWakeup lock];
    ALCFlowDataQueue *queue = [self.packetsQueue valueForKey:[NSString stringWithFormat:@"%d", packet.codecDescriptor.track.type]];
    [queue enqueue:@[packet]];
    [self.packetWakeup unlock];
}

- (SCFlowData *)dequeuePacket {
    [self.packetWakeup lock];
    int streamIndex = -1;
    double min = DBL_MAX;
    for (NSString *key in self.packetsQueue) {
       if (self.packetsQueue[key].size == 0) {
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
    SCFlowData * packet = [self.packetsQueue[@(streamIndex).stringValue] dequeue];
    [self.timeStamps setValue:@(packet.timeStamp) forKey:@(streamIndex).stringValue];
    int total = 0;
    for (NSString *key in self.packetsQueue) {
        total += self.packetsQueue[key].size;
    }
    BOOL isFull = total > 10 * 1024 * 1024;
    if (!isFull) {
        [self.packetWakeup signal];
    }
    [self.packetWakeup unlock];
    return packet;
}

#pragma mark - frame queue

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
