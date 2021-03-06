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
#import "SCControl.h"
#import "SCFrame.h"

#import "SCPlayerControlView.h"
#import "Athena-Swift.h"

@interface SCPlayerViewController () <ControllerProtocol>

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) SCPlayerControlView *controlView;

@property (nonatomic, strong) Controller *controler;
//@property (nonatomic, strong) SCControl *controler;
@property (nonatomic, assign) BOOL isHideContainer;
@property (nonatomic, assign) BOOL isTouchSlider;

@end

@implementation SCPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Aimer.mkv"];
    [self.controler openWithPath:path];
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
    [self.controler close];
}

- (void)setup {
    self.view.backgroundColor = [UIColor blackColor];
    self.mtkView              = [[MTKView alloc] initWithFrame:self.view.bounds];
    self.controlView          = [[SCPlayerControlView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.mtkView];
    [self.mtkView addSubview:self.controlView];
    
    self.controler = [[Controller alloc] initWithRenderView:self.mtkView];
    self.controler.delegate = self;
    
    [self.controlView.actionButton addTarget:self action:@selector(resumeOrPause) forControlEvents:UIControlEventTouchUpInside];
    [self.controlView.backButton addTarget:self action:@selector(popVC) forControlEvents:UIControlEventTouchUpInside];
    [self.controlView.progressSlide addTarget:self action:@selector(seekingTime:) forControlEvents:UIControlEventTouchUpInside];
    [self.controlView.progressSlide addTarget:self action:@selector(touchSlider) forControlEvents:UIControlEventTouchDown];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showOrHideView)];
    [self.controlView addGestureRecognizer:tap];
}

- (void)showOrHideView {
    [self.controlView hideAll:!self.isHideContainer];
    self.isHideContainer = !self.isHideContainer;
}

- (void)resumeOrPause {
    if (self.controler.state == SCControlStatePlaying) {
        [self.controler pause];
        [self.controlView settingPause];
    } else if (self.controler.state == SCControlStatePaused) {
        [self.controler resume];
        [self.controlView settingPlay];
    }
//    [self.controler switchVideoDecoder];
}

- (void)popVC {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)touchSlider {
    self.isTouchSlider = YES;
}

- (void)seekingTime:(id)sender {
    [self.controler seekingWithTime:self.controlView.progressSlide.value];
    self.isTouchSlider = NO;
}


- (void)controlCenterWithController:(Controller * _Nonnull)controller didRender:(double)position duration:(double)duration {
    NSInteger length = duration;
    NSInteger playing = position;
    NSString *total = [NSString stringWithFormat:@"%02lu:%02lu:%02lu", length / 3600, length % 3600 / 60, length % 3600 % 60];
    if (!self.isTouchSlider) {
        NSString *current = [NSString stringWithFormat:@"%02lu:%02lu:%02lu", playing / 3600, playing % 3600 / 60, playing % 3600 % 60];
        self.controlView.timeLabel.text = [NSString stringWithFormat:@"%@/%@", current, total];
        self.controlView.progressSlide.value = (float)playing / length;
    } else {
        NSUInteger result = self.controlView.progressSlide.value * length;
        NSString *current = [NSString stringWithFormat:@"%02lu:%02lu:%02lu", result / 3600, result % 3600 / 60, result % 3600 % 60];
        self.controlView.timeLabel.text = [NSString stringWithFormat:@"%@/%@", current, total];
    }
}

@end
