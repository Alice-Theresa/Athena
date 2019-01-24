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
#import "SCNV12VideoFrame.h"
#import "SCAudioFrame.h"

#import "SCAudioDecoder.h"
#import "SCVTDecoder.h"
#import "SCVideoDecoder.h"

#import "SCRender.h"

@interface SCControl () <SCAudioManagerDelegate>

@property (nonatomic, strong) SCFormatContext *context;

@property (nonatomic, strong) SCVTDecoder *VTDecoder;
@property (nonatomic, strong) SCVideoDecoder *videoDecoder;
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
@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, assign) BOOL needSeeking;
@property (nonatomic, assign) NSTimeInterval seekingTime;
@property (nonatomic, assign) BOOL hardwareDecode;

@end

static AVPacket flush_packet;

@implementation SCControl

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (instancetype)initWithRenderView:(MTKView *)view {
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            av_init_packet(&flush_packet);
            flush_packet.data = (uint8_t *)&flush_packet;
            flush_packet.duration = 0;
        });
        
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (void)openFile:(NSString *)filename {
    _context = [[SCFormatContext alloc] init];
    [_context openFile:filename];
    
    _VTDecoder    = [[SCVTDecoder alloc] initWithFormatContext:_context];
    _videoDecoder = [[SCVideoDecoder alloc] initWithFormatContext:_context];
    _audioDecoder = [[SCAudioDecoder alloc] initWithFormatContext:_context];
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
    self.seekingTime = percentage * self.context.duration;
    self.needSeeking = YES;
}

- (void)switchVideoDecoder {
    self.hardwareDecode = !self.hardwareDecode;
}

- (void)flushQueue {
    [self.videoFrameQueue flush];
    [self.audioFrameQueue flush];
    [self.videoPacketQueue flush];
    [self.audioPacketQueue flush];
}

#pragma mark - reading, decoding and rendering

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
        if (self.needSeeking) {
            [self.context seekingTime:self.seekingTime];
            [self flushQueue];
            [self.videoPacketQueue enqueuePacket:flush_packet];
            [self.audioPacketQueue enqueuePacket:flush_packet];
            self.needSeeking = NO;
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
            if (packet.data == flush_packet.data) {
                avcodec_flush_buffers(self.context.videoCodecContext);
                [self.videoFrameQueue flush];
                continue;
            }
            if (packet.data != NULL && packet.stream_index >= 0) {
                if (self.hardwareDecode) {
                    [self.videoFrameQueue enqueueArrayAndSort:[self.videoDecoder decode:packet]];
                } else {
                    [self.videoFrameQueue enqueueArrayAndSort:[self.VTDecoder decode:packet]];
                }
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
            if (packet.data == flush_packet.data) {
                avcodec_flush_buffers(self.context.audioCodecContext);
                [self.audioFrameQueue flush];
                continue;
            }
            if (packet.data != NULL && packet.stream_index >= 0) {
                [self.audioFrameQueue enqueueArray:[self.audioDecoder decode:packet]];
            }
        }
    }
}

- (void)rendering {
    NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
    if (currentTime > self.interval) {
        SCFrame *frame = [self.videoFrameQueue dequeueFrame];
        if (frame == nil) {
            return;
        }
        self.interval = frame.duration + currentTime;
        [self.render render:(id<SCRenderDataInterface>)frame drawIn:self.mtkView];
        if ([self.delegate respondsToSelector:@selector(controlCenter:didRender:duration:)] && !self.needSeeking) {
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

- (void)appWillResignActive {
    [self pause];
}

@end
