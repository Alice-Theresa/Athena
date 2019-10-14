//
//  SCRenderLayer.m
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <MetalKit/MetalKit.h>
#import "SCRenderLayer.h"
#import "SCDemuxLayer.h"
#import "SCFormatContext.h"
#import "SCControl.h"
#import "SCFrameQueue.h"
#import "SCAudioFrame.h"
#import "SCFrame.h"
#import "SCRender.h"
#import "SCSynchronizer.h"
#import "SCAudioManager.h"

@interface SCRenderLayer () <SCAudioManagerDelegate, MTKViewDelegate>

@property (nonatomic, strong) SCFrameQueue *videoFrameQueue;
@property (nonatomic, strong) SCFrameQueue *audioFrameQueue;

@property (nonatomic, strong) SCFormatContext *context;
@property (nonatomic, assign) SCControlState controlState;

@property (nonatomic, strong) SCFrame *videoFrame;
@property (nonatomic, strong) SCAudioFrame *audioFrame;

@property (nonatomic, strong) SCRender *render;
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) SCSynchronizer *syncor;

@end

@implementation SCRenderLayer

- (instancetype)initWithContext:(SCFormatContext *)context
                     renderView:(MTKView *)view
                          video:(SCFrameQueue *)videoFrameQueue
                          audio:(SCFrameQueue *)audioFrameQueue {
    if (self = [super init]) {
        _context = context;
        _videoFrameQueue = videoFrameQueue;
        _audioFrameQueue = audioFrameQueue;
        
        _render           = [[SCRender alloc] init];
        _mtkView = view;
        _mtkView.device = _render.device;
        _mtkView.depthStencilPixelFormat = MTLPixelFormatInvalid;
        _mtkView.framebufferOnly = false;
        _mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
        _mtkView.delegate = self;
        
        [SCAudioManager shared].delegate = self;
        
        _syncor = [[SCSynchronizer alloc] init];
    }
    return self;
}

- (void)start {
    [[SCAudioManager shared] play];
}

- (void)resume {
    [[SCAudioManager shared] play];
    self.controlState = SCControlStatePlaying;
    self.mtkView.paused = NO;
}

- (void)pause {
    [[SCAudioManager shared] stop];
    self.controlState = SCControlStatePaused;
    self.mtkView.paused = YES;
}

- (void)close {
    [[SCAudioManager shared] stop];
    self.controlState = SCControlStateClosed;
}

- (void)rendering {
    if (!self.videoFrame) {
        self.videoFrame = [self.videoFrameQueue dequeueFrame];
        if (!self.videoFrame) {
            return;
        }
    }
    if (![self.syncor shouldRenderVideoFrame:self.videoFrame.position duration:self.videoFrame.duration]) {
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
            if (!self.audioFrame) {
                memset(outputData, 0, numberOfFrames * numberOfChannels * sizeof(SInt16));
                break;
            }
            [self.syncor updateAudioClock:self.audioFrame.position];
            
            const Byte * bytes = (Byte *)self.audioFrame.sampleData.bytes + self.audioFrame->output_offset;
            const NSUInteger bytesLeft = self.audioFrame.sampleData.length - self.audioFrame->output_offset;
            const NSUInteger frameSizeOf = numberOfChannels * sizeof(SInt16);
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

@end
