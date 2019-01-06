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
#import "SCVideoFrameQueue.h"
#import "SCVideoFrame.h"
#import "SCFormatContext.h"
#import "SCDemuxer.h"

@interface VideoDecodeViewController ()

@property (nonatomic, strong) AAPLEAGLLayer *glLayer;
@property (nonatomic, strong) SCDemuxer *decoder;
@property (nonatomic, strong) CADisplayLink *mDispalyLink;

@end

@implementation VideoDecodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.glLayer = [[AAPLEAGLLayer alloc] initWithFrame:self.view.bounds];
    [self.view.layer addSublayer:self.glLayer];
    
    self.decoder = [[SCDemuxer alloc] init];
    [self.decoder open];
    
    self.mDispalyLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame)];
    self.mDispalyLink.frameInterval = 2;
    [self.mDispalyLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.mDispalyLink setPaused:YES];
    [self.decoder stop];
}

- (void)updateFrame {
    _glLayer.pixelBuffer = [[SCVideoFrameQueue shared] getFrame].pixelBuffer;
}

@end
