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
#import "SCMetalManager.h"
#import "SCFrameQueue.h"
#import "SCVideoFrame.h"
#import "SCControl.h"

@interface SCPlayerViewController () <MTKViewDelegate>

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) SCControl *controler;
@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;

@end

@implementation SCPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CVMetalTextureCacheCreate(0, nil, [SCMetalManager shared].device, nil, &_textureCache);
    [self.view addSubview:self.mtkView];
    self.controler = [[SCControl alloc] init];
    [self.controler open];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.controler stop];
}

- (MTKView *)mtkView {
    if (!_mtkView) {
        _mtkView = [[MTKView alloc] initWithFrame:self.view.bounds device:[SCMetalManager shared].device];
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
        SCVideoFrame *frame = [self.controler.videoFrameQueue dequeueFrame];
        self.interval = frame.duration + currentTime;
        [[SCMetalManager shared] renderPixelBuffer:frame.pixelBuffer drawIn:view];
    } else {
        NSLog(@"pass");
    }
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}


@end
