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

#import "SCSynchronizer.h"
#import "SCFrame.h"
#import "SCAudioFrame.h"

#import "SCAudioDecoder.h"
#import "SCVTDecoder.h"
#import "SCVideoDecoder.h"
#import "SCDecoderInterface.h"
#import "SCFrameQueue.h"
#import "SCPacketQueue.h"
#import "SCRender.h"

@interface SCControl () <SCAudioManagerDelegate, MTKViewDelegate>

@property (nonatomic, strong) SCFormatContext *context;

@property (nonatomic, strong) SCVTDecoder *VTDecoder;
@property (nonatomic, strong) SCVideoDecoder *videoDecoder;
@property (nonatomic, strong) id<SCDecoderInterface> currentDecoder;
@property (nonatomic, strong) SCAudioDecoder *audioDecoder;

@property (nonatomic, strong) SCPacketQueue *videoPacketQueue;
@property (nonatomic, strong) SCPacketQueue *audioPacketQueue;
@property (nonatomic, strong) SCFrameQueue *videoFrameQueue;
@property (nonatomic, strong) SCFrameQueue *audioFrameQueue;

@property (nonatomic, strong) NSInvocationOperation *readPacketOperation;
@property (nonatomic, strong) NSInvocationOperation *videoDecodeOperation;
@property (nonatomic, strong) NSInvocationOperation *audioDecodeOperation;
@property (nonatomic, strong) NSOperationQueue *controlQueue;

@property (nonatomic, strong) SCRender *render;
@property (nonatomic, weak  ) MTKView *mtkView;

@property (nonatomic, assign, readwrite) SCControlState controlState;

@property (nonatomic, assign) BOOL isSeeking;
@property (nonatomic, assign) NSTimeInterval videoSeekingTime;
@property (nonatomic, strong) SCSynchronizer *syncor;

@property (nonatomic, strong) SCFrame *videoFrame;
@property (nonatomic, strong) SCAudioFrame *audioFrame;


@end

@implementation SCControl

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (instancetype)initWithRenderView:(MTKView *)view {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        
        _videoFrameQueue  = [[SCFrameQueue alloc] init];
        _audioFrameQueue  = [[SCFrameQueue alloc] init];
        _videoPacketQueue = [[SCPacketQueue alloc] init];
        _audioPacketQueue = [[SCPacketQueue alloc] init];
        _render           = [[SCRender alloc] init];
        
        _mtkView = view;
        _mtkView.device = _render.device;
        _mtkView.depthStencilPixelFormat = MTLPixelFormatInvalid;
        _mtkView.framebufferOnly = false;
        _mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
        _mtkView.delegate = self;
        
        _syncor = [[SCSynchronizer alloc] init];
    }
    return self;
}

- (void)appWillResignActive {
    [self pause];
}

- (void)openPath:(NSString *)filename {
    _context = [[SCFormatContext alloc] init];
    [_context openPath:filename];
    
    _VTDecoder    = [[SCVTDecoder alloc] initWithFormatContext:_context];
    _videoDecoder = [[SCVideoDecoder alloc] initWithFormatContext:_context];
    _audioDecoder = [[SCAudioDecoder alloc] initWithFormatContext:_context];
    _currentDecoder = _VTDecoder;
    [SCAudioManager shared].delegate = self;
    [self start];
}

- (void)start {
    self.readPacketOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(readPacket) object:nil];
    self.readPacketOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.readPacketOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    self.videoDecodeOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodeVideoFrame) object:nil];
    self.videoDecodeOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.videoDecodeOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    self.audioDecodeOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodeAudioFrame) object:nil];
    self.audioDecodeOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.audioDecodeOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    self.controlQueue = [[NSOperationQueue alloc] init];
    self.controlQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.controlQueue addOperation:self.readPacketOperation];
    [self.controlQueue addOperation:self.videoDecodeOperation];
    [self.controlQueue addOperation:self.audioDecodeOperation];
    
    [[SCAudioManager shared] play];
    self.controlState = SCControlStatePlaying;
}

- (void)pause {
    self.controlState = SCControlStatePaused;
    [[SCAudioManager shared] stop];
    self.mtkView.paused = YES;
}

- (void)resume {
    self.controlState = SCControlStatePlaying;
    [[SCAudioManager shared] play];
    self.mtkView.paused = NO;
}

- (void)close {
    self.controlState = SCControlStateClosed;
    [self.controlQueue cancelAllOperations];
    [self.controlQueue waitUntilAllOperationsAreFinished];
    self.readPacketOperation = nil;
    self.videoDecodeOperation = nil;
    self.audioDecodeOperation = nil;
    [self flushQueue];
    [[SCAudioManager shared] stop];
    [self.context closeFile];
}

- (void)seekingTime:(NSTimeInterval)percentage {
    self.videoSeekingTime = percentage * self.context.duration;
    [self.syncor block];
    self.isSeeking = YES;
}

- (void)switchToHardwareDecode:(BOOL)isHardware {
    self.currentDecoder = isHardware ? self.VTDecoder : self.videoDecoder;
}

- (void)flushQueue {
    [self.videoFrameQueue flush];
    [self.audioFrameQueue flush];
    [self.videoPacketQueue flush];
    [self.audioPacketQueue flush];
}

#pragma mark - reading

- (void)readPacket {
    BOOL finished = NO;
    while (!finished) {
        if (self.controlState == SCControlStateClosed) {
            break;
        }
        if (self.controlState == SCControlStatePaused) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if (self.videoPacketQueue.packetTotalSize + self.audioPacketQueue.packetTotalSize > 10 * 1024 * 1024) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if (self.isSeeking) {
            [self.context seekingTime:self.videoSeekingTime];
            [self flushQueue];
            [self.videoPacketQueue enqueueDiscardPacket];
            [self.audioPacketQueue enqueueDiscardPacket];
            self.isSeeking = NO;
            continue;
        }
        AVPacket packet;
        av_init_packet(&packet);
        int result = [self.context readFrame:&packet];
        if (result < 0) {
            NSLog(@"read packet error");
            finished = YES;
            break;
        } else {
            if (packet.stream_index == self.context.videoIndex) {
                [self.videoPacketQueue enqueuePacket:packet];
            } else if (packet.stream_index == self.context.audioIndex) {
                [self.audioPacketQueue enqueuePacket:packet];
            } else if (packet.stream_index == self.context.subtitleIndex) {

            }
        }
    }
}

#pragma mark - decoding

- (void)decodeVideoFrame {
    while (self.controlState != SCControlStateClosed) {
        if (self.controlState == SCControlStatePaused) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if (self.videoFrameQueue.count > 10) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        @autoreleasepool {
            AVPacket packet = [self.videoPacketQueue dequeuePacket];
            if (packet.flags == AV_PKT_FLAG_DISCARD) {
                avcodec_flush_buffers(self.context.videoCodecContext);
                [self.videoFrameQueue flush];
                [self.syncor unblock];
                continue;
            }
            if (packet.data != NULL && packet.stream_index >= 0) {
                NSArray<SCFrame *> *frames = [self.currentDecoder decode:packet];
                [self.videoFrameQueue enqueueFramesAndSort:frames];
            }
        }
    }
}

- (void)decodeAudioFrame {
    while (self.controlState != SCControlStateClosed) {
        if (self.controlState == SCControlStatePaused) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if (self.audioFrameQueue.count > 10) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        @autoreleasepool {
            AVPacket packet = [self.audioPacketQueue dequeuePacket];
            if (packet.flags == AV_PKT_FLAG_DISCARD) {
                avcodec_flush_buffers(self.context.audioCodecContext);
                [self.audioFrameQueue flush];
                [self.syncor unblock];
                continue;
            }
            if (packet.data != NULL && packet.stream_index >= 0) {
                NSArray<SCFrame *> *frames = [self.audioDecoder decode:packet];
                [self.audioFrameQueue enqueueFramesAndSort:frames];
            }
        }
    }
}

#pragma mark - rendering

- (void)rendering {
    if (!self.videoFrame) {
        self.videoFrame = [self.videoFrameQueue dequeueFrame];
    }
    if (!self.videoFrame) {
        return;
    }
    if (![self.syncor shouldRenderVideoFrame:self.videoFrame.position duration:self.videoFrame.duration]) {
        return;
    }
    [self.render render:(id<SCRenderDataInterface>)self.videoFrame drawIn:self.mtkView];
    if ([self.delegate respondsToSelector:@selector(controlCenter:didRender:duration:)] && !self.isSeeking) {
        [self.delegate controlCenter:self didRender:self.videoFrame.position duration:self.context.duration];
    }
    self.videoFrame = nil;
}

#pragma mark - audio delegate

- (void)fetchoutputData:(float *)outputData numberOfFrames:(UInt32)numberOfFrames numberOfChannels:(UInt32)numberOfChannels {
    @autoreleasepool {
        while (numberOfFrames > 0) {
            if (!self.audioFrame) {
                self.audioFrame = (SCAudioFrame *)[self.audioFrameQueue dequeueFrame];
                if (self.audioFrame) {
                    [self.syncor updateAudioClock:self.audioFrame.position];
                }
            }
            if (!self.audioFrame) {
                memset(outputData, 0, numberOfFrames * numberOfChannels * sizeof(float));
                return;
            }
            
            const Byte * bytes = (Byte *)self.audioFrame->samples + self.audioFrame->output_offset;
            const NSUInteger bytesLeft = self.audioFrame->length - self.audioFrame->output_offset;
            const NSUInteger frameSizeOf = numberOfChannels * sizeof(float);
            const NSUInteger bytesToCopy = MIN(numberOfFrames * frameSizeOf, bytesLeft);
            const NSUInteger framesToCopy = bytesToCopy / frameSizeOf;
            
            memcpy(outputData, bytes, bytesToCopy);
            numberOfFrames -= framesToCopy;
            outputData += framesToCopy * numberOfChannels;
            
            if (bytesToCopy < bytesLeft) {
                self.audioFrame->output_offset += bytesToCopy;
            } else {
                self.audioFrame = nil;
            }
        }
    }
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    [self rendering];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {}

@end
