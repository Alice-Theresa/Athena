//
//  VideoDecodeViewController.m
//  Athena
//
//  Created by Theresa on 2018/12/21.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import "VideoDecodeViewController.h"
#import "AAPLEAGLLayer.h"
#import <VideoToolbox/VideoToolbox.h>
#import "VideoHardwareDecoder.h"

@interface VideoDecodeViewController () <VideoDecoderDelegate>

@property (nonatomic, strong) AAPLEAGLLayer *glLayer;
@property (nonatomic, strong) VideoHardwareDecoder *decoder;
@property (nonatomic, strong) CADisplayLink *mDispalyLink;

@end

@implementation VideoDecodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.glLayer = [[AAPLEAGLLayer alloc] initWithFrame:self.view.bounds];
    [self.view.layer addSublayer:self.glLayer];
    
    self.decoder = [[VideoHardwareDecoder alloc] initWithStream:[[NSInputStream alloc] initWithFileAtPath:[[NSBundle mainBundle] pathForResource:@"mtv" ofType:@"h264"]]];
    self.decoder.delegate = self;

    [self.decoder startDecode];
    
    self.mDispalyLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame)];
    self.mDispalyLink.frameInterval = 2;
    [self.mDispalyLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.mDispalyLink setPaused:YES];
    [self.decoder stopDecode];
}

- (void)updateFrame {
    [self.decoder decodeFrame];
}

- (void)fetch:(CVPixelBufferRef)buffer {
    _glLayer.pixelBuffer = buffer;
}

@end
