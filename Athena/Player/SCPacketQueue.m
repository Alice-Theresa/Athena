//
//  PacketQueue.m
//  Athena
//
//  Created by Theresa on 2018/12/27.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import "SCPacketQueue.h"

@interface SCPacketQueue ()

@property (nonatomic, strong) NSCondition *condition;
@property (nonatomic, strong) NSMutableArray <NSValue *> * packets;

@end

@implementation SCPacketQueue

+ (instancetype)shared {
    static SCPacketQueue *queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[SCPacketQueue alloc] init];
    });
    return queue;
}

- (instancetype)init {
    if (self = [super init]) {
        self.packets = [NSMutableArray array];
        self.condition = [[NSCondition alloc] init];
    }
    return self;
}

- (void)putPacket:(AVPacket)packet {
    [self.condition lock];
    NSValue * value = [NSValue value:&packet withObjCType:@encode(AVPacket)];
    [self.packets addObject:value];
    [self.condition unlock];
}

- (AVPacket)getPacket {
    [self.condition lock];
    AVPacket packet;
    if (self.packets.count <= 0) {
        [self.condition unlock];
        return packet; //need checkout
    }
    [self.packets.firstObject getValue:&packet];
    [self.packets removeObjectAtIndex:0];
    [self.condition unlock];
    return packet;
}

- (void)flush {
    [self.condition lock];
    [self.packets removeAllObjects];
    [self.condition unlock];
}

@end
