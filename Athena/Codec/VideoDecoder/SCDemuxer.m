//
//  SCDemuxer.m
//  Athena
//
//  Created by Theresa on 2018/12/29.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import "SCFormatContext.h"
#import "SCDemuxer.h"
#import "SCPacketQueue.h"
#import "SCVideoFrameQueue.h"
#import "SCHardwareDecoder.h"

@interface SCDemuxer ()

@property (nonatomic, strong) SCFormatContext *context;
@property (nonatomic, strong) SCHardwareDecoder *decoder;

@property (nonatomic, strong) NSInvocationOperation *readPacketOperation;
@property (nonatomic, strong) NSInvocationOperation *decodeOperation;
@property (nonatomic, strong) NSOperationQueue *controlQueue;

@end

@implementation SCDemuxer

- (instancetype)init {
    if (self = [super init]) {
        _context = [[SCFormatContext alloc] init];
        _decoder = [[SCHardwareDecoder alloc] initWithFormatContext:_context];
        
        
    }
    return self;
}

- (void)open {
    self.readPacketOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(readPacket) object:nil];
    self.readPacketOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.readPacketOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    self.decodeOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodeFrame) object:nil];
    self.decodeOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.decodeOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    self.controlQueue = [[NSOperationQueue alloc] init];
    self.controlQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.controlQueue addOperation:self.readPacketOperation];
    [self.controlQueue addOperation:self.decodeOperation];
}

- (void)readPacket {
    while (YES) {
        AVPacket packet;
        av_init_packet(&packet);
        int result = [self.context readFrame:&packet];
        if (result < 0) {
            NSLog(@"read packet error");
            break;
        } else {
            if (packet.stream_index == self.context.videoIndex) {
                [[SCPacketQueue shared] putPacket:packet];
            }
        }
    }
}

- (void)decodeFrame {
    while (YES) {
        if ([SCVideoFrameQueue shared].count > 10) {
            [NSThread sleepForTimeInterval:0.03];
        }
        [[SCVideoFrameQueue shared] putFrame:[self.decoder decode]];
    }
}

- (void)pause {
    self.controlQueue.suspended = YES;
}

- (void)resume {
    self.controlQueue.suspended = NO;
}

- (void)stop {
    [self.readPacketOperation cancel];
    [self.decodeOperation cancel];
}

@end
