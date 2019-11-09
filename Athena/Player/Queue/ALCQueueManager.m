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
#import "SCFrame.h"
#import "SCTrack.h"
#import "SCFormatContext.h"
#import "SCFrameQueue.h"

@interface ALCQueueManager ()

@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@property (nonatomic, copy  ) NSDictionary<NSString *, SCPacketQueue *> *packetsQueue;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *timeStamps;

@property (nonatomic, strong) SCFrameQueue *videoFrameQueue;
@property (nonatomic, strong) SCFrameQueue *audioFrameQueue;

@end

@implementation ALCQueueManager

- (instancetype)initWithContext:(SCFormatContext *)context {
    if (self = [super init]) {
        _semaphore       = dispatch_semaphore_create(1);
        _packetsQueue    = [NSMutableDictionary dictionary];
        _timeStamps      = [NSMutableDictionary dictionary];
        _videoFrameQueue = [[SCFrameQueue alloc] init];
        _audioFrameQueue = [[SCFrameQueue alloc] init];
        for (SCTrack *track in context.tracks) {
            [_packetsQueue setValue:[[SCPacketQueue alloc] init] forKey:[NSString stringWithFormat:@"%d", track.index]];
        }
    }
    return self;
}

#pragma mark -

- (BOOL)packetQueueIsFull {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    int total = 0;
    for (NSString *key in self.packetsQueue) {
        total += self.packetsQueue[key].packetTotalSize;
    }
    BOOL isFull = total > 10 * 1024 * 1024;
    dispatch_semaphore_signal(self.semaphore);
    return isFull;
}

- (void)flushPacketQueue {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    for (NSString *key in self.packetsQueue) {
        [self.packetsQueue[key] flush];
        [self.packetsQueue[key] enqueueDiscardPacket];
    }
    [self.timeStamps removeAllObjects];
    dispatch_semaphore_signal(self.semaphore);
}

- (void)enqueuePacket:(SCPacket *)packet {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    SCPacketQueue *queue = [self.packetsQueue valueForKey:[NSString stringWithFormat:@"%d", packet.core->stream_index]];
    [queue enqueuePacket:packet];
    dispatch_semaphore_signal(self.semaphore);
}

- (SCPacket *)dequeuePacket {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
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
       return nil;
    }
    SCPacket *packet = [self.packetsQueue[@(streamIndex).stringValue] dequeuePacket];
    [self.timeStamps setValue:@(packet.timeStamp) forKey:@(streamIndex).stringValue];
    dispatch_semaphore_signal(self.semaphore);
    return packet;
}

#pragma mark -

- (BOOL)frameQueueIsFull {
    return NO;
}

- (void)flushFrameQueue {

}

- (void)enqueueFrames:(NSArray<SCFrame *> *)frames {
    
}

//- (SCFrame *)dequeueFrameByQueueIndex:(NSNumber *)index {
//
//}

@end
