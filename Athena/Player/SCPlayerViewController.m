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
#import "SCFrameQueue.h"
#import "SCFrame.h"
#import "SCRenderDataInterface.h"
#import "SCPlayerControlView.h"

@interface SCPlayerViewController ()

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) SCPlayerControlView *controlView;

@property (nonatomic, strong) SCControl *controler;
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
    self.controler = [[SCControl alloc] initWithRenderView:self.mtkView];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.mtkView = [[MTKView alloc]  initWithFrame:self.view.bounds];
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
    } else {
        [self.controler resume];
        [self.controlView settingPlay];
    }
}

- (void)popVC {
    [self.navigationController popViewControllerAnimated:YES];
}

- (SCPlayerControlView *)controlView {
    if (!_controlView) {
        _controlView = [[SCPlayerControlView alloc] initWithFrame:self.view.bounds];
    }
    return _controlView;
}

@end
