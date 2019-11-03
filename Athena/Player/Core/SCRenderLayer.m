//
//  SCRenderLayer.m
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <MetalKit/MetalKit.h>
#import "SCRenderLayer.h"
#import "SCFormatContext.h"
#import "SCFrameQueue.h"
#import "SCAudioFrame.h"
#import "SCVideoFrame.h"
#import "SCRender.h"
#import "SCSynchronizer.h"
#import "SCAudioManager.h"
#import "SCPlayerState.h"
#import "SCDecoderLayer.h"

@interface SCRenderLayer () <SCAudioManagerDelegate, MTKViewDelegate, DecodeToQueueProtocol>

@property (nonatomic, strong) SCFrameQueue *videoFrameQueue;
@property (nonatomic, strong) SCFrameQueue *audioFrameQueue;

@property (nonatomic, strong) SCFormatContext *context;
@property (nonatomic, assign) SCPlayerState   controlState;
@property (nonatomic, strong) SCRender        *render;
@property (nonatomic, strong) MTKView         *mtkView;

@property (nonatomic, strong) SCVideoFrame *videoFrame;
@property (nonatomic, strong) SCAudioFrame *audioFrame;
@property (nonatomic, strong) SCSynchronizer *syncor;

@end

@implementation SCRenderLayer

- (instancetype)initWithContext:(SCFormatContext *)context decoderLayer:(SCDecoderLayer *)decoderLayer renderView:(MTKView *)view {
    if (self = [super init]) {
        _context = context;
        _videoFrameQueue  = [[SCFrameQueue alloc] init];
        _audioFrameQueue  = [[SCFrameQueue alloc] init];
        _syncor = [[SCSynchronizer alloc] init];
        _render = [[SCRender alloc] init];
        
        self.mtkView.frame = view.bounds;
        [view insertSubview:self.mtkView atIndex:0];
        
        decoderLayer.delegate = self;
        [SCAudioManager shared].delegate = self;
    }
    return self;
}

- (void)start {
    [[SCAudioManager shared] play];
}

- (void)resume {
    [[SCAudioManager shared] play];
    self.controlState = SCPlayerStatePlaying;
    self.mtkView.paused = NO;
}

- (void)pause {
    [[SCAudioManager shared] stop];
    self.controlState = SCPlayerStatePaused;
    self.mtkView.paused = YES;
}

- (void)close {
    [[SCAudioManager shared] stop];
    self.controlState = SCPlayerStateClosed;
}

- (void)rendering {
    if (!self.videoFrame) {
        self.videoFrame = [self.videoFrameQueue dequeueFrame];
        if (!self.videoFrame || self.videoFrame.type == SCFrameTypeDiscard) {
            self.videoFrame = nil;
            return;
        }
    }
    if (![self.syncor shouldRenderVideoFrame:self.videoFrame.timeStamp duration:self.videoFrame.duration]) {
        return;
    }
    [self.render render:(id<SCRenderDataInterface>)self.videoFrame drawIn:self.mtkView];
//    if ([self.delegate respondsToSelector:@selector(controlCenter:didRender:duration:)] && !self.isSeeking) {
//        [self.delegate controlCenter:self didRender:self.videoFrame.position duration:self.context.duration];
//    }
    self.videoFrame = nil;
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    [self rendering];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {}

#pragma mark - audio delegate

- (void)fetchoutputData:(SInt16 *)outputData numberOfFrames:(UInt32)numberOfFrames numberOfChannels:(UInt32)numberOfChannels {
    @autoreleasepool {
        while (numberOfFrames > 0) {
            if (!self.audioFrame) {
                self.audioFrame = (SCAudioFrame *)[self.audioFrameQueue dequeueFrame];
            }
            if (!self.audioFrame || self.audioFrame.type == SCFrameTypeDiscard) {
                memset(outputData, 0, numberOfFrames * numberOfChannels * sizeof(SInt16));
                self.audioFrame = nil;
                break;
            }
            [self.syncor updateAudioClock:self.audioFrame.timeStamp];
            
            Byte * bytes = (Byte *)self.audioFrame.sampleData.bytes + self.audioFrame.outputOffset;
            NSUInteger bytesLeft = self.audioFrame.sampleData.length - self.audioFrame.outputOffset;
            NSUInteger frameSizeOf = numberOfChannels * sizeof(SInt16);
            NSUInteger bytesToCopy = MIN(numberOfFrames * frameSizeOf, bytesLeft);
            NSUInteger framesToCopy = bytesToCopy / frameSizeOf;
            
            memcpy(outputData, bytes, bytesToCopy);
            numberOfFrames -= framesToCopy;
            outputData += framesToCopy * numberOfChannels;
            
            if (bytesToCopy < bytesLeft) {
                self.audioFrame.outputOffset += bytesToCopy;
            } else {
                self.audioFrame = nil;
            }
        }
    }
}

- (MTKView *)mtkView {
    if (!_mtkView) {
        _mtkView                         = [[MTKView alloc] initWithFrame:CGRectZero];
        _mtkView.device                  = self.render.device;
        _mtkView.depthStencilPixelFormat = MTLPixelFormatInvalid;
        _mtkView.framebufferOnly         = false;
        _mtkView.colorPixelFormat        = MTLPixelFormatBGRA8Unorm;
        _mtkView.delegate = self;
    }
    return _mtkView;
}

- (void)audioFrameQueueFlush {
    [self.audioFrameQueue flush];
}

- (BOOL)audioFrameQueueIsFull {
    return self.audioFrameQueue.count > 5;
}

- (void)enqueueAudioFrames:(nonnull NSArray<SCFrame *> *)frames {
    [self.audioFrameQueue enqueueFramesAndSort:frames];
}

- (void)enqueueVideoFrames:(nonnull NSArray<SCFrame *> *)frames {
    [self.videoFrameQueue enqueueFramesAndSort:frames];
}

- (void)videoFrameQueueFlush {
    [self.videoFrameQueue flush];
}

- (BOOL)videoFrameQueueIsFull {
    return self.videoFrameQueue.count > 5;
}

@end
