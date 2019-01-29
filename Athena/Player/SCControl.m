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


#import "SCFrame.h"
#import "SCAudioFrame.h"

#import "SCAudioDecoder.h"
#import "SCVTDecoder.h"
#import "SCVideoDecoder.h"
#import "SCDecoderInterface.h"
#import "SCFrameQueue.h"
#import "SCPacketQueue.h"
#import "SCRender.h"

@interface SCControl () <SCAudioManagerDelegate>

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
@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, strong) SCAudioFrame *currentAudioFrame;

@property (nonatomic, assign, readwrite) SCControlState controlState;

@property (nonatomic, assign) BOOL isSeeking;
@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, assign) NSTimeInterval videoSeekingTime;
@property (nonatomic, assign) NSTimeInterval audioSeekingTime;

@end

@implementation SCControl

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (instancetype)initWithRenderView:(MTKView *)view {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(rendering)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        
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
        
        _videoSeekingTime = INT_MIN;
        _audioSeekingTime = INT_MIN;
    }
    return self;
}

- (void)appWillResignActive {
    [self pause];
}

- (void)openFile:(NSString *)filename {
    _context = [[SCFormatContext alloc] init];
    [_context openFile:filename];
    
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
    [self.displayLink setPaused:YES];
}

- (void)resume {
    self.controlState = SCControlStatePlaying;
    [[SCAudioManager shared] play];
    [self.displayLink setPaused:NO];
}

- (void)close {
    self.controlState = SCControlStateClosed;
    [self.displayLink invalidate];
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
    self.audioSeekingTime = self.videoSeekingTime;
    self.isSeeking = YES;
}

- (void)switchToHardwareDecode:(BOOL)isHardware {
    self.currentDecoder = isHardware ? self.VTDecoder : self.videoDecoder;
}

- (void)flushQueue {
    [self.videoFrameQueue flushAndBlock];
    [self.audioFrameQueue flushAndBlock];
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
            if (packet.data != NULL && packet.stream_index >= 0) {
                NSArray<SCFrame *> *frames = [self.currentDecoder decode:packet];
                if (fabs(frames.lastObject.duration + frames.lastObject.position - self.videoSeekingTime) < 0.1) {
                    [self.videoFrameQueue unblock];
                    self.videoSeekingTime = INT_MIN;
                    continue;
                }
                if (self.videoSeekingTime >= 0) {
                    continue;
                }
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
            if (packet.data != NULL && packet.stream_index >= 0) {
                NSArray<SCFrame *> *frames = [self.audioDecoder decode:packet];
                if (fabs(frames.lastObject.duration + frames.lastObject.position - self.videoSeekingTime) < 0.1) {
                    [self.audioFrameQueue unblock];
                    self.audioSeekingTime = INT_MIN;
                    continue;
                }
                if (self.audioSeekingTime >= 0) {
                    continue;
                }
                [self.audioFrameQueue enqueueFramesAndSort:frames];
            }
        }
    }
}

#pragma mark - rendering

- (void)rendering {
    NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
    if (currentTime > self.interval) {
        SCFrame *frame = [self.videoFrameQueue dequeueFrame];
        if (frame == nil) {
            return;
        }
        self.interval = frame.duration + currentTime;
        [self.render render:(id<SCRenderDataInterface>)frame drawIn:self.mtkView];
        if ([self.delegate respondsToSelector:@selector(controlCenter:didRender:duration:)] && !self.isSeeking) {
            [self.delegate controlCenter:self didRender:frame.position duration:self.context.duration];
        }
    }
}

#pragma mark - audio delegate

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
