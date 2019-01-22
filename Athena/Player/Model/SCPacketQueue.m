//
//  PacketQueue.m
//  Athena
//
//  Created by Theresa on 2018/12/27.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import "SCPacketQueue.h"

@interface SCPacketQueue ()

@property (nonatomic, assign, readwrite) NSUInteger packetTotalSize;

@property (nonatomic, strong) NSCondition *condition;
@property (nonatomic, strong) NSMutableArray <NSValue *> *packets;

@end

@implementation SCPacketQueue

- (instancetype)init {
    if (self = [super init]) {
        self.packets = [NSMutableArray array];
        self.condition = [[NSCondition alloc] init];
    }
    return self;
}

- (void)enqueuePacket:(AVPacket)packet {
    [self.condition lock];
    self.packetTotalSize += packet.size;
    NSValue *value = [NSValue value:&packet withObjCType:@encode(AVPacket)];
    [self.packets addObject:value];
    [self.condition unlock];
}

- (AVPacket)dequeuePacket {
    [self.condition lock];
    AVPacket packet;
    packet.stream_index = -1;
    if (self.packets.count <= 0) {
        [self.condition unlock];
        return packet;
    }
    [self.packets.firstObject getValue:&packet];
    [self.packets removeObjectAtIndex:0];
    self.packetTotalSize -= packet.size;
    [self.condition unlock];
    return packet;
}

- (void)flush {
    [self.condition lock];
    [self.packets removeAllObjects];
    self.packetTotalSize = 0;
    [self.condition unlock];
}

@end
