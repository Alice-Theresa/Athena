//
//  SCControl.m
//  Athena
//
//  Created by Theresa on 2018/12/29.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import "ALCFormatContext.h"
#import "SCAudioManager.h"
#import "SCControl.h"

#import "ALCSynchronizer.h"
#import "SCAudioFrame.h"
#import "ALCPacketQueue.h"
#import "ALCFrameQueue.h"

#import "SCAudioDecoder.h"
#import "SCVideoDecoder.h"
#import "SCRender.h"

#import "SCDemuxLoop.h"
#import "SCRenderLayer.h"
#import "SCDecoderLayer.h"

@interface SCControl () 

@property (nonatomic, strong) ALCFormatContext *context;
@property (nonatomic, strong) UIView *view;

@property (nonatomic, assign, readwrite) SCPlayerState controlState;
@property (nonatomic, strong) ALCPacketQueue *packetQueue;
@property (nonatomic, strong) ALCFrameQueue *frameQueue;

@property (nonatomic, strong) SCDemuxLoop *demuxLayer;
@property (nonatomic, strong) SCRenderLayer *renderLayer;
@property (nonatomic, strong) SCDecoderLayer *decoderLayer;

@end

@implementation SCControl

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithRenderView:(UIView *)view {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        _view = view;
    }
    return self;
}

- (void)appWillResignActive {
    [self pause];
}

- (void)openPath:(NSString *)filename {
    _context = [[ALCFormatContext alloc] init];
    BOOL success = [_context openPath:filename];
    if (!success) {
        return;
    }
    self.packetQueue = [[ALCPacketQueue alloc] initWithContext:self.context];
    self.frameQueue = [[ALCFrameQueue alloc] init];
    self.demuxLayer   = [[SCDemuxLoop alloc] initWithContext:self.context queueManager:self.packetQueue];
    self.decoderLayer = [[SCDecoderLayer alloc] initWithContext:self.context packetQueue:self.packetQueue frameQueue:self.frameQueue];
    self.renderLayer  = [[SCRenderLayer alloc] initWithContext:self.context frameQueue:self.frameQueue renderView:(MTKView *)self.view];
    [self start];
}

- (void)start {
    [self.demuxLayer start];
    [self.renderLayer start];
    [self.decoderLayer start];
    self.controlState = SCPlayerStatePlaying;
}

- (void)pause {
    [self.demuxLayer pause];
    [self.decoderLayer pause];
    [self.renderLayer pause];
    self.controlState = SCPlayerStatePaused;
}

- (void)resume {
    [self.demuxLayer resume];
    [self.decoderLayer resume];
    [self.renderLayer resume];
    self.controlState = SCPlayerStatePlaying;
}

- (void)close {
    [self.packetQueue destory];
    [self.frameQueue destory];
    [self.demuxLayer close];
    [self.decoderLayer close];
    [self.renderLayer close];
    self.controlState = SCPlayerStateClosed;
    [self.context closeFile];
}

- (void)seekingTime:(NSTimeInterval)percentage {
    NSTimeInterval videoSeekingTime = percentage * self.context.duration;
    NSLog(@"%f", videoSeekingTime);
    [self.demuxLayer seekingTime:videoSeekingTime];
}

@end
