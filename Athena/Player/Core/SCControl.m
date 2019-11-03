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
@property (nonatomic, strong) UIView *view;

@property (nonatomic, assign, readwrite) SCPlayerState controlState;

@property (nonatomic, strong) SCDemuxLayer *demuxLayer;
@property (nonatomic, strong) SCRenderLayer *renderLayer;
@property (nonatomic, strong) SCDecoderLayer *decoderLayer;

@end

@implementation SCControl

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
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
    _context = [[SCFormatContext alloc] init];
    [_context openPath:filename];
    
    self.demuxLayer = [[SCDemuxLayer alloc] initWithContext:self.context];
    self.decoderLayer = [[SCDecoderLayer alloc] initWithContext:self.context demuxLayer:self.demuxLayer];
    self.renderLayer = [[SCRenderLayer alloc] initWithContext:self.context decoderLayer:self.decoderLayer renderView:(MTKView *)self.view];
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
    [self.demuxLayer close];
    [self.decoderLayer close];
    [self.renderLayer close];
    self.controlState = SCPlayerStateClosed;
    [self.context closeFile];
}

- (void)seekingTime:(NSTimeInterval)percentage {
    NSTimeInterval videoSeekingTime = percentage * self.context.duration;
    [self.demuxLayer seekingTime:videoSeekingTime];
}

@end
