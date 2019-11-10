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
@property (nonatomic, strong) NSMutableArray <SCPacket *> *packets;

@end

@implementation SCPacketQueue

- (instancetype)init {
    if (self = [super init]) {
        self.packets = [NSMutableArray array];
    }
    return self;
}

- (void)enqueueDiscardPacket {
    SCPacket *packet = [[SCPacket alloc] init];
    packet.core->flags = AV_PKT_FLAG_DISCARD;
    self.packetTotalSize += packet.core->size;
    [self.packets addObject:packet];
}

- (void)enqueuePacket:(SCPacket *)packet {
    self.packetTotalSize += packet.core->size;
    [self.packets addObject:packet];
}

- (SCPacket *)dequeuePacket {
    SCPacket *packet;
    if (self.packets.count <= 0) {
        return packet;
    }
    packet = self.packets.firstObject;
    [self.packets removeObjectAtIndex:0];
    self.packetTotalSize -= packet.core->size;
    return packet;
}

- (void)flush {
    [self.packets removeAllObjects];
    self.packetTotalSize = 0;
}

@end
