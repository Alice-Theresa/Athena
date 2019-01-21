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
#import "SCFrameQueue.h"
#import "SCNV12VideoFrame.h"
#import "SCControl.h"
#import "SCI420VideoFrame.h"
#import "SCRenderDataInterface.h"
#import "TestUtil.h"

@interface SCPlayerViewController () <MTKViewDelegate>

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) SCControl *controler;
@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, strong) SCRender *render;

@end

@implementation SCPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.mtkView];
    self.controler = [[SCControl alloc] init];
    [self.controler open];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.controler stop];
}

- (SCRender *)render {
    if (!_render) {
        _render = [[SCRender alloc] init];
    }
    return _render;
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
//    [self.render render:[[SCNV12VideoFrame alloc] initWithAVPixelBuffer:[TestUtil createNV12From:[UIImage imageNamed:@"test.jpg"]]] drawIn:view];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

@end
