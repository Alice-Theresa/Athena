//
//  AudioCaptureManager.m
//  Athena
//
//  Created by Theresa on 2017/9/30.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "AudioCaptureManager.h"
#import "SharedQueue.h"

@interface AudioCaptureManager ()

@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCaptureDeviceInput *inputDevice;
@property (nonatomic, strong) AVCaptureAudioDataOutput *outputData;

@end

@implementation AudioCaptureManager

+ (instancetype)shared {
    static AudioCaptureManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[AudioCaptureManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _audioSession = [AVAudioSession sharedInstance];
        _captureSession = [[AVCaptureSession alloc] init];
    }
    return self;
}

- (void)settingAudioSession {
    NSError *error;
    [self.audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    [self.audioSession setMode:AVAudioSessionModeVideoRecording error:&error];
    [self.audioSession setActive:YES error:&error];
}

- (void)addAudioInputOutput:(id<AVCaptureAudioDataOutputSampleBufferDelegate>)delegate {
    NSError *error;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    self.inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if ([self.captureSession canAddInput:self.inputDevice]) {
        [self.captureSession addInput:self.inputDevice];
    } else {
        NSLog(@"Capture session add input failed");
    }
    
    self.outputData = [[AVCaptureAudioDataOutput alloc] init];
    [self.outputData setSampleBufferDelegate:delegate queue:[SharedQueue audioBuffer]];
    if ([self.captureSession canAddOutput:self.outputData]) {
        [self.captureSession addOutput:self.outputData];
    } else {
        NSLog(@"Capture session add output failed");
    }
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
