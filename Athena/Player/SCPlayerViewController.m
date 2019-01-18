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

@interface SCPlayerViewController () <MTKViewDelegate>

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) SCControl *controler;
@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;
@property (nonatomic, strong) SCRender *render;

@end

@implementation SCPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CVMetalTextureCacheCreate(0, nil, self.render.device, nil, &_textureCache);
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
//    NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
//    if (currentTime > self.interval) {
//        SCFrame *frame = [self.controler.videoFrameQueue dequeueFrame];
//        if (frame == nil) {
//            return;
//        }
//        self.interval = frame.duration + currentTime;
//
//        [self.render render:frame drawIn:view];
//    }
    [self.render render:[[SCNV12VideoFrame alloc] initWithAVPixelBuffer:[self pixelBufferFromImage:[UIImage imageNamed:@"test.jpg"].CGImage]] drawIn:view];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (CVPixelBufferRef)pixelBufferFromImage:(CGImageRef)image {
    MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:self.render.device];
    id<MTLTexture> texture = [loader newTextureWithCGImage:image options:nil error:nil];
    
    CVPixelBufferRef pixelBuffer = NULL;
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    MTLRegion region = MTLRegionMake2D(0, 0, CGImageGetWidth(image), CGImageGetHeight(image));
    NSUInteger bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    unsigned char *baseAddressY  = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    [texture getBytes:baseAddressY bytesPerRow:CGImageGetWidth(image) fromRegion:region mipmapLevel:0];
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}

@end
