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

- (MTKView *)mtkView {
    if (!_mtkView) {
        _mtkView = [[MTKView alloc] initWithFrame:self.view.bounds device:[SCMetalManager shared].device];
        _mtkView.depthStencilPixelFormat = MTLPixelFormatInvalid;
        _mtkView.framebufferOnly = false;
//        _mtkView.paused = true;
        _mtkView.delegate = self;
        _mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    }
    return _mtkView;
}

- (void)drawInMTKView:(MTKView *)view {
    
    NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
//    if (currentTime > self.interval) {
        SCVideoFrame *frame = [self.controler.videoFrameQueue dequeueFrame];
        self.interval = frame.duration + currentTime;
        
    
        CVMetalTextureRef texture;
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                  _textureCache,
                                                  frame.pixelBuffer,
                                                  nil,
                                                  MTLPixelFormatBGRA8Unorm,
                                                  CVPixelBufferGetWidthOfPlane(frame.pixelBuffer, 0),
                                                  CVPixelBufferGetHeightOfPlane(frame.pixelBuffer, 0),
                                                  0,
                                                  &texture);
//        MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:[SCMetalManager shared].device];
//        NSError *error;
//        id<MTLTexture> text = [loader newTextureWithCGImage:[UIImage imageNamed:@"test.jpg"].CGImage options:nil error:&error];
        [[SCMetalManager shared] renderTexture:CVMetalTextureGetTexture(texture) drawIn:view];
//    }
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

@end
