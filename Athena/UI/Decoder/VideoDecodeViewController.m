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
#import "SCHardwareDecoder.h"
#import "SCFrameQueue.h"
#import "SCVideoFrame.h"
#import "SCFormatContext.h"
#import "SCControl.h"
#import "SCFrame.h"

#import "SCAudioFrame.h"

@interface VideoDecodeViewController () 

@property (nonatomic, strong) AAPLEAGLLayer *glLayer;
@property (nonatomic, strong) SCControl *decoder;
@property (nonatomic, strong) CADisplayLink *mDispalyLink;
@property (nonatomic, assign) NSTimeInterval interval;

@end

@implementation VideoDecodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.glLayer = [[AAPLEAGLLayer alloc] initWithFrame:self.view.bounds];
    [self.view.layer addSublayer:self.glLayer];
    
    self.decoder = [[SCControl alloc] init];
    [self.decoder open];
    
    self.mDispalyLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame)];
    [self.mDispalyLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.mDispalyLink setPaused:YES];
    [self.decoder stop];
}

- (void)updateFrame {
    NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
    if (currentTime > self.interval) {
        SCVideoFrame *frame = [self.decoder.videoFrameQueue dequeueFrame];
        self.interval = frame.duration + currentTime;
        _glLayer.pixelBuffer = frame.pixelBuffer;
    }
    
}

@end
