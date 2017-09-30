//
//  CaptureManager.m
//  Athena
//
//  Created by Theresa on 2017/9/30.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "CaptureManager.h"

@interface CaptureManager ()

@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) dispatch_queue_t queue;
//@property (nonatomic, strong) NSFileHandle *audioFileHandle;

@end

@implementation CaptureManager

+ (instancetype)shared {
    static CaptureManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CaptureManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _audioSession = [AVAudioSession sharedInstance];
        _captureSession = [[AVCaptureSession alloc] init];
        _queue = dispatch_queue_create("com.audio.queue", DISPATCH_QUEUE_SERIAL);
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
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if ([self.captureSession canAddInput:input]) {
        [self.captureSession addInput:input];
    } else {
        NSLog(@"Capture session add input failed");
    }
    
    AVCaptureAudioDataOutput *output = [[AVCaptureAudioDataOutput alloc] init];
    [output setSampleBufferDelegate:delegate queue:self.queue];
    if ([self.captureSession canAddOutput:output]) {
        [self.captureSession addOutput:output];
    } else {
        NSLog(@"Capture session add output failed");
    }
}

- (void)startCapture {
    [self.captureSession startRunning];
//    NSString *audioFile = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"abc.aac"];
//    [[NSFileManager defaultManager] removeItemAtPath:audioFile error:nil];
//    [[NSFileManager defaultManager] createFileAtPath:audioFile contents:nil attributes:nil];
//    self.audioFileHandle = [NSFileHandle fileHandleForWritingAtPath:audioFile];
}

- (void)stopCapture {
    [self.captureSession stopRunning];
//    [self.audioFileHandle closeFile];
//    self.audioFileHandle = nil;
}

@end
