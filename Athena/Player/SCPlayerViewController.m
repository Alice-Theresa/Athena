//
//  SCPlayerViewController.m
//  Athena
//
//  Created by Theresa on 2019/01/15.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <MetalKit/MetalKit.h>
#import <CoreVideo/CoreVideo.h>
#import "SCPlayerViewController.h"
#import "SCRender.h"
#import "SCControl.h"
#import "SCFrameQueue.h"
#import "SCFrame.h"
#import "SCRenderDataInterface.h"
#import "SCPlayerControlView.h"

@interface SCPlayerViewController () <MTKViewDelegate>

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) SCPlayerControlView *controlView;

@property (nonatomic, strong) SCControl *controler;
@property (nonatomic, strong) SCRender *render;

@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, assign) BOOL isHideContainer;

@end

@implementation SCPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    [self.controler open];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setHidden:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.controler stop];
}

- (void)setup {
    self.render = [[SCRender alloc] init];
    self.controler = [[SCControl alloc] init];
    
    self.view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.mtkView];
    [self.mtkView addSubview:self.controlView];
    
    [self.controlView.actionButton addTarget:self action:@selector(resumeOrPause) forControlEvents:UIControlEventTouchUpInside];
    [self.controlView.backButton addTarget:self action:@selector(popVC) forControlEvents:UIControlEventTouchUpInside];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showOrHideView)];
    [self.controlView addGestureRecognizer:tap];
}

- (void)showOrHideView {
    [self.controlView hideAll:!self.isHideContainer];
    self.isHideContainer = !self.isHideContainer;
}

- (void)resumeOrPause {
    if (self.controler.isPlaying) {
        [self.controler pause];
        [self.controlView settingPause];
        self.mtkView.paused = YES;
    } else {
        [self.controler resume];
        [self.controlView settingPlay];
        self.mtkView.paused = NO;
    }
}

- (void)popVC {
    [self.navigationController popViewControllerAnimated:YES];
}

- (MTKView *)mtkView {
    if (!_mtkView) {
        _mtkView = [[MTKView alloc] initWithFrame:self.view.bounds device:self.render.device];
        _mtkView.depthStencilPixelFormat = MTLPixelFormatInvalid;
        _mtkView.framebufferOnly = false;
        _mtkView.delegate = self;
        _mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    }
    return _mtkView;
}

- (SCPlayerControlView *)controlView {
    if (!_controlView) {
        _controlView = [[SCPlayerControlView alloc] initWithFrame:self.view.bounds];
    }
    return _controlView;
}

#pragma mark - delegate

- (void)drawInMTKView:(MTKView *)view {
    NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
    if (currentTime > self.interval) {
        SCFrame *frame = [self.controler.videoFrameQueue dequeueFrame];
        if (frame == nil) {
            return;
        }
        self.interval = frame.duration + currentTime;
        [self.render render:(id<SCRenderDataInterface>)frame drawIn:view];
    }
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

@end
