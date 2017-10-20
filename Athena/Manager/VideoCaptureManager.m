//
//  VideoCaptureManager.m
//  Athena
//
//  Created by Theresa on 2017/10/19.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "VideoCaptureManager.h"
#import "SharedQueue.h"

@interface VideoCaptureManager ()

@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCaptureDeviceInput *inputDevice;
@property (nonatomic, strong) AVCaptureVideoDataOutput *outputData;

@end

@implementation VideoCaptureManager

+ (instancetype)shared {
    static VideoCaptureManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[VideoCaptureManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _captureSession = [[AVCaptureSession alloc] init];
        _captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
    }
    return self;
}

- (void)addVideoInputOutput:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)delegate {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if ([self.captureSession canAddInput:self.inputDevice]) {
        [self.captureSession addInput:self.inputDevice];
    } else {
        NSLog(@"Capture session add input failed");
    }
    
    self.outputData = [[AVCaptureVideoDataOutput alloc] init];
    NSDictionary *settings = @{(__bridge id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)};
    self.outputData.videoSettings = settings;
    [self.outputData setSampleBufferDelegate:delegate queue:[SharedQueue audioBuffer]];
    if ([self.captureSession canAddOutput:self.outputData]) {
        [self.captureSession addOutput:self.outputData];
    } else {
        NSLog(@"Capture session add output failed");
    }
    
    AVCaptureConnection *connection = [self.outputData connectionWithMediaType:AVMediaTypeVideo];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
}

- (AVCaptureSession *)currentCaptureSession {
    return self.captureSession;
}

- (void)clearCapture {
    [self.captureSession removeInput:self.inputDevice];
    [self.captureSession removeOutput:self.outputData];
}

- (void)startCapture {
    [self.captureSession startRunning];
}

- (void)stopCapture {
    [self.captureSession stopRunning];
}

@end
