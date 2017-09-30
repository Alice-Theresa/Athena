//
//  ViewController.m
//  Athena
//
//  Created by Theresa on 2017/9/30.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "ViewController.h"
#import "CaptureManager.h"

@interface ViewController () <AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) CaptureManager *manager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.manager = [CaptureManager shared];
    [self.manager settingAudioSession];
    [self.manager addAudioInputOutput:self];
    [self.manager startCapture];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

    
    
}

@end
