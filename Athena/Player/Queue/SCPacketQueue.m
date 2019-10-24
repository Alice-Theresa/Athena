//
//  PacketQueue.m
//  Athena
//
//  Created by Theresa on 2018/12/27.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import "SCPacketQueue.h"
#import "SCPacket.h"

@interface SCPacketQueue ()

@property (nonatomic, assign, readwrite) NSUInteger packetTotalSize;

@property (nonatomic, strong) NSCondition *condition;
@property (nonatomic, strong) NSMutableArray <SCPacket *> *packets;

@end

@implementation SCPacketQueue

- (instancetype)init {
    if (self = [super init]) {
        self.packets = [NSMutableArray array];
        self.condition = [[NSCondition alloc] init];
    }
    return self;
}

- (void)enqueueDiscardPacket {
    [self.condition lock];
    SCPacket *packet = [[SCPacket alloc] init];
    packet.core->flags = AV_PKT_FLAG_DISCARD;
    self.packetTotalSize += packet.core->size;
//    AVPacket packet;
//    av_init_packet(&packet);
//    self.packetTotalSize += packet.size;
//    packet.flags = AV_PKT_FLAG_DISCARD;
//    NSValue *value = [NSValue value:&packet withObjCType:@encode(AVPacket)];
    [self.packets addObject:packet];
    [self.condition unlock];
}

- (void)enqueuePacket:(SCPacket *)packet {
    [self.condition lock];
    self.packetTotalSize += packet.core->size;
//    NSValue *value = [NSValue value:&packet withObjCType:@encode(AVPacket)];
    [self.packets addObject:packet];
    [self.condition unlock];
}

- (SCPacket *)dequeuePacket {
    [self.condition lock];
//    AVPacket packet;
//    packet.stream_index = -1;
    SCPacket *packet;
    if (self.packets.count <= 0) {
        [self.condition unlock];
        return packet;
    }
//    [self.packets.firstObject getValue:&packet];
    packet = self.packets.firstObject;
    [self.packets removeObjectAtIndex:0];
    self.packetTotalSize -= packet.core->size;
    [self.condition unlock];
    return packet;
}

- (void)flush {
    [self.condition lock];
//    for (NSValue * value in self.packets) {
//        AVPacket packet;
//        [value getValue:&packet];
//        av_packet_unref(&packet);
//    }
    [self.packets removeAllObjects];
    self.packetTotalSize = 0;
    [self.condition unlock];
}

@end
