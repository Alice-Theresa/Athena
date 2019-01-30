//
//  SCPacketQueue.m
//  Athena
//
//  Created by Theresa on 2019/01/29.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCPacketQueue.h"
#import "SCPacketNode.h"

@interface SCPacketQueue ()

@property (nonatomic, assign, readwrite) NSUInteger packetTotalSize;
@property (nonatomic, assign, readwrite) NSInteger count;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@property (nonatomic, strong) SCPacketNode *header;
@property (nonatomic, strong) SCPacketNode *tailer;

@end

@implementation SCPacketQueue

- (void)dealloc {
    NSLog(@"Packet Queue dealloc");
}

- (instancetype)init {
    if (self = [super init]) {
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)enqueuePacket:(AVPacket)packet {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    
    SCPacketNode *node = [[SCPacketNode alloc] initWithPacket:[NSValue value:&packet withObjCType:@encode(AVPacket)]];
    if (self.count == 0) {
        self.header = node;
        self.tailer = node;
    } else {
        self.tailer.next = node;
        self.tailer = node;
    }
    self.packetTotalSize += packet.size;
    self.count++;
    dispatch_semaphore_signal(self.semaphore);
}

- (AVPacket)dequeuePacket {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    AVPacket packet;
    packet.stream_index = -1;
    if (self.count <= 0) {
        dispatch_semaphore_signal(self.semaphore);
        return packet;
    }
    [self.header.packet getValue:&packet];
    self.header = self.header.next;
    self.packetTotalSize -= packet.size;
    self.count--;
    dispatch_semaphore_signal(self.semaphore);
    return packet;
}

- (void)flush {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    SCPacketNode *release = self.header;
    while (release.packet) {
        AVPacket packet;
        [release.packet getValue:&packet];
        av_packet_unref(&packet);
        release = release.next;
    }
    self.header = nil;
    self.tailer = nil;
    self.packetTotalSize = 0;
    self.count = 0;
    dispatch_semaphore_signal(self.semaphore);
}

@end
