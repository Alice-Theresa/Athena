//
//  SCControl.m
//  Athena
//
//  Created by Theresa on 2018/12/29.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import "SCFormatContext.h"
#import "SCAudioManager.h"
#import "SCControl.h"
#import "SCPacketQueue.h"
#import "SCFrameQueue.h"

#import "SCFrame.h"
#import "SCVideoFrame.h"
#import "SCAudioFrame.h"

#import "SCAudioDecoder.h"
#import "SCHardwareDecoder.h"
#import "SCSoftwareDecoder.h"

@interface SCControl () <SCAudioManagerDelegate>

@property (nonatomic, strong) SCFormatContext *context;
@property (nonatomic, strong) SCHardwareDecoder *videoDecoder;
@property (nonatomic, strong) SCSoftwareDecoder *videoFFDecoder;
@property (nonatomic, strong) SCAudioDecoder *audioDecoder;

@property (nonatomic, strong) NSInvocationOperation *readPacketOperation;
@property (nonatomic, strong) NSInvocationOperation *decodeOperation;
@property (nonatomic, strong) NSOperationQueue *controlQueue;

@property (nonatomic, strong) SCAudioFrame *currentAudioFrame;

@end

@implementation SCControl

- (instancetype)init {
    if (self = [super init]) {
        _context = [[SCFormatContext alloc] init];
        _videoFrameQueue = [[SCFrameQueue alloc] init];
        _audioFrameQueue = [[SCFrameQueue alloc] init];
        
        _videoDecoder = [[SCHardwareDecoder alloc] initWithFormatContext:_context];
        _videoFFDecoder = [[SCSoftwareDecoder alloc] initWithFormatContext:_context];
        _audioDecoder = [[SCAudioDecoder alloc] initWithFormatContext:_context audioFrameQueue:_audioFrameQueue];
        [SCAudioManager shared].delegate = self;
    }
    return self;
}

- (void)open {
    self.readPacketOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(readPacket) object:nil];
    self.readPacketOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.readPacketOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    self.decodeOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodeVideoFrame) object:nil];
    self.decodeOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.decodeOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    self.controlQueue = [[NSOperationQueue alloc] init];
    self.controlQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.controlQueue addOperation:self.readPacketOperation];
    [self.controlQueue addOperation:self.decodeOperation];
    
    [[SCAudioManager shared] play];
    
}

- (void)readPacket {
    while (!self.controlQueue.isSuspended) {
        AVPacket packet;
        av_init_packet(&packet);
        int result = [self.context readFrame:&packet];
        if (result < 0) {
            NSLog(@"read packet error");
            break;
        } else {
            if (packet.stream_index == self.context.videoIndex) {
                [[SCPacketQueue shared] putPacket:packet];
            } else if (packet.stream_index == self.context.audioIndex) {
                [self.audioDecoder synchronizedDecode:packet];
            }
        }
    }
}

- (void)decodeVideoFrame {
    while (!self.controlQueue.isSuspended) {
        if (self.videoFrameQueue.count > 10) {
            [NSThread sleepForTimeInterval:0.03];
        }
        AVPacket packet = [[SCPacketQueue shared] getPacket];
//        [self.videoFrameQueue enqueueAndSort:[self.videoFFDecoder decode:packet]];
        [self.videoFrameQueue enqueueAndSort:[self.videoDecoder decode:packet]];
    }
}

- (void)pause {
    self.controlQueue.suspended = YES;
}

- (void)resume {
    self.controlQueue.suspended = NO;
}

- (void)stop {
    self.controlQueue.suspended = YES;
    [self.readPacketOperation cancel];
    [self.decodeOperation cancel];
    [self.videoFrameQueue flush];
    [self.audioFrameQueue flush];
    [[SCPacketQueue shared] flush];
    [[SCAudioManager shared] stop];
}

- (void)fetchoutputData:(float *)outputData numberOfFrames:(UInt32)numberOfFrames numberOfChannels:(UInt32)numberOfChannels {
    @autoreleasepool {
        while (numberOfFrames > 0) {
            if (!self.currentAudioFrame) {
                self.currentAudioFrame = (SCAudioFrame *)[self.audioFrameQueue dequeueFrame];
            }
            if (!self.currentAudioFrame) {
                memset(outputData, 0, numberOfFrames * numberOfChannels * sizeof(float));
                return;
            }
            
            const Byte * bytes = (Byte *)self.currentAudioFrame->samples + self.currentAudioFrame->output_offset;
            const NSUInteger bytesLeft = self.currentAudioFrame->length - self.currentAudioFrame->output_offset;
            const NSUInteger frameSizeOf = numberOfChannels * sizeof(float);
            const NSUInteger bytesToCopy = MIN(numberOfFrames * frameSizeOf, bytesLeft);
            const NSUInteger framesToCopy = bytesToCopy / frameSizeOf;
            
            memcpy(outputData, bytes, bytesToCopy);
            numberOfFrames -= framesToCopy;
            outputData += framesToCopy * numberOfChannels;
            
            if (bytesToCopy < bytesLeft) {
                self.currentAudioFrame->output_offset += bytesToCopy;
            } else {
                self.currentAudioFrame = nil;
            }
        }
    }
    
}

@end
