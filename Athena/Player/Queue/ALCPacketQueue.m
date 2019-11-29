//
//  ALCPacketQueue.m
//  Athena
//
//  Created by skylar on 2019/11/29.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "ALCPacketQueue.h"
#import "SCPacket.h"
#import "ALCTrack.h"
#import "ALCFormatContext.h"

#import "ALCFlowDataQueue.h"
#import "ALCCodecDescriptor.h"

#define PacketTotalMaxsize 10 * 1024 * 1024

@interface ALCPacketQueue ()

@property (nonatomic, strong) NSCondition *packetWakeup;
@property (nonatomic, copy  ) NSDictionary<NSString *, ALCFlowDataQueue *> *packetsQueue;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *timeStamps;

@end

@implementation ALCPacketQueue

- (void)destory {
    [self.packetWakeup lock];
    [self.packetWakeup broadcast];
    [self.packetWakeup unlock];
}

- (instancetype)initWithContext:(ALCFormatContext *)context {
    if (self = [super init]) {
        _packetWakeup = [[NSCondition alloc] init];
        _packetsQueue    = [NSMutableDictionary dictionary];
        _timeStamps      = [NSMutableDictionary dictionary];
        for (ALCTrack *track in context.tracks) {
            ALCFlowDataQueue *queue = [[ALCFlowDataQueue alloc] init];
            queue.type = track.type;
            [_packetsQueue setValue:queue forKey:[NSString stringWithFormat:@"%d", track.index]];
        }
    }
    return self;
}

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

        ALCCodecDescriptor *cd = [[ALCCodecDescriptor alloc] init];
        cd.track = [[ALCTrack alloc] initWithIndex:-1 type:self.packetsQueue[key].type meta:NULL];
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

@end
