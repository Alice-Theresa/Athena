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

#import "SCDemuxLayer.h"
#import "SCRenderLayer.h"
#import "SCDecoderLayer.h"

@interface SCControl () 

@property (nonatomic, strong) SCFormatContext *context;

@property (nonatomic, strong) SCVTDecoder *VTDecoder;
@property (nonatomic, strong) SCVideoDecoder *videoDecoder;
@property (nonatomic, strong) id<SCDecoderInterface> currentDecoder;
@property (nonatomic, strong) SCAudioDecoder *audioDecoder;

@property (nonatomic, strong) SCFrameQueue *videoFrameQueue;
@property (nonatomic, strong) SCFrameQueue *audioFrameQueue;

@property (nonatomic, weak  ) MTKView *mtkView;

@property (nonatomic, assign, readwrite) SCControlState controlState;

@property (nonatomic, strong) SCDemuxLayer *demuxLayer;
@property (nonatomic, strong) SCRenderLayer *renderLayer;
@property (nonatomic, strong) SCDecoderLayer *decoderLayer;

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
        _mtkView = view;
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
    _currentDecoder = _videoDecoder;
    
    self.demuxLayer = [[SCDemuxLayer alloc] initWithContext:self.context];
    self.renderLayer = [[SCRenderLayer alloc] initWithContext:self.context renderView:self.mtkView video:self.videoFrameQueue audio:self.audioFrameQueue];
    self.decoderLayer = [[SCDecoderLayer alloc] initWithContext:self.context
                                                     demuxLayer:self.demuxLayer
                                                          video:self.videoFrameQueue
                                                          audio:self.audioFrameQueue];
    [self start];
}

- (void)start {
    [self.demuxLayer start];
    [self.renderLayer start];
    [self.decoderLayer start];
    
    self.controlState = SCControlStatePlaying;
}

- (void)pause {
    [self.demuxLayer pause];
    [self.decoderLayer pause];
    [self.renderLayer pause];
    self.controlState = SCControlStatePaused;
}

- (void)resume {
    [self.demuxLayer resume];
    [self.decoderLayer resume];
    [self.renderLayer resume];
    self.controlState = SCControlStatePlaying;
}

- (void)close {
    [self.demuxLayer close];
    [self.decoderLayer close];
    [self.renderLayer close];
    self.controlState = SCControlStateClosed;
    [self.context closeFile];
}

- (void)seekingTime:(NSTimeInterval)percentage {
    NSTimeInterval videoSeekingTime = percentage * self.context.duration;
    [self.demuxLayer seekingTime:videoSeekingTime];
}

@end
