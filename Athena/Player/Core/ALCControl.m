//
//  SCControl.m
//  Athena
//
//  Created by Theresa on 2018/12/29.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import "ALCFormatContext.h"
#import "ALCAudioManager.h"
#import "ALCControl.h"

#import "ALCSynchronizer.h"
#import "ALCAudioFrame.h"
#import "ALCPacketQueue.h"
#import "ALCFrameQueue.h"

#import "ALCAudioDecoder.h"
#import "ALCVideoDecoder.h"
#import "ALCRender.h"

#import "ALCDemuxLoop.h"
#import "ALCRenderLoop.h"
#import "ALCDecoderLoop.h"

@interface ALCControl () 

@property (nonatomic, strong) ALCFormatContext *context;
@property (nonatomic, strong) UIView *view;

@property (nonatomic, assign, readwrite) NSTimeInterval currentPosition;
@property (nonatomic, assign, readwrite) ALCPlayerState controlState;
@property (nonatomic, strong) ALCPacketQueue *packetQueue;
@property (nonatomic, strong) ALCFrameQueue *frameQueue;

@property (nonatomic, strong) ALCDemuxLoop *demuxLayer;
@property (nonatomic, strong) ALCRenderLoop *renderLayer;
@property (nonatomic, strong) ALCDecoderLoop *decoderLayer;

@end

@implementation ALCControl

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
    self.packetQueue  = [[ALCPacketQueue alloc] initWithContext:self.context];
    self.frameQueue   = [[ALCFrameQueue alloc] init];
    self.demuxLayer   = [[ALCDemuxLoop alloc] initWithContext:self.context packetQueue:self.packetQueue];
    self.decoderLayer = [[ALCDecoderLoop alloc] initWithContext:self.context packetQueue:self.packetQueue frameQueue:self.frameQueue];
    self.renderLayer  = [[ALCRenderLoop alloc] initWithContext:self.context frameQueue:self.frameQueue renderView:(MTKView *)self.view];
    [self start];
}

- (void)start {
    [self.demuxLayer start];
    [self.renderLayer start];
    [self.decoderLayer start];
    self.controlState = ALCPlayerStatePlaying;
}

- (void)pause {
    [self.demuxLayer pause];
    [self.decoderLayer pause];
    [self.renderLayer pause];
    self.controlState = ALCPlayerStatePaused;
}

- (void)resume {
    [self.demuxLayer resume];
    [self.decoderLayer resume];
    [self.renderLayer resume];
    self.controlState = ALCPlayerStatePlaying;
}

- (void)close {
    [self.demuxLayer close];
    [self.decoderLayer close];
    [self.renderLayer close];
    [self.packetQueue destory];
    [self.frameQueue destory];
    self.controlState = ALCPlayerStateClosed;
    [self.context closeFile];
}

- (void)seekingTime:(NSTimeInterval)percentage {
    NSTimeInterval videoSeekingTime = percentage * self.context.duration;
    NSLog(@"%f", videoSeekingTime);
    [self.demuxLayer seekingTime:videoSeekingTime];
}

@end
