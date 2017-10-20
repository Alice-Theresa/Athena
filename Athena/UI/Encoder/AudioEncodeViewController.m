//
//  ViewController.m
//  Athena
//
//  Created by Theresa on 2017/9/30.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "AACEncoderInterface.h"
#import "AudioEncodeViewController.h"
#import "SharedQueue.h"

#import "AudioCaptureManager.h"
#import "AACHardEncoder.h"
#import "AACSoftEncoder.h"

@interface AudioEncodeViewController () <AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AudioCaptureManager *manager;
@property (nonatomic, strong) NSFileHandle *audioFileHandle;
@property (nonatomic, strong) id<AACEncoderInterface> encoder;
@property (weak, nonatomic) IBOutlet UISwitch *encoderSwitch;

@end

@implementation AudioEncodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"AAC编码";
    self.encoder = [[AACHardEncoder alloc] initWithEncoderQueue:[SharedQueue audioEncode] callbackQueue:[SharedQueue audioCallback]];
    self.manager = [AudioCaptureManager shared];
    [self.manager settingAudioSession];
    [self.manager addAudioInputOutput:self];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stopRecordingAndCloseFile];
    [self.manager clearCapture];
}

- (IBAction)recordingOrNot:(id)sender {
    UISwitch *switcher = sender;
    if (switcher.isOn) {
        self.encoderSwitch.enabled = NO;
        [self startRecordingAndOpenFile];
    } else {
        self.encoderSwitch.enabled = YES;
        [self stopRecordingAndCloseFile];
    }
}

- (IBAction)switchEncoder:(id)sender {
    UISwitch *switcher = sender;
    if (switcher.isOn) {
        self.encoder = [[AACHardEncoder alloc] initWithEncoderQueue:[SharedQueue audioEncode] callbackQueue:[SharedQueue audioCallback]];
    } else {
        self.encoder = [[AACSoftEncoder alloc] initWithEncoderQueue:[SharedQueue audioEncode] callbackQueue:[SharedQueue audioCallback]];
    }
    if (!self.encoder) {
        [self showAlert];
    }
}

#pragma mark - private

- (void)startRecordingAndOpenFile {
    NSString *fileName = [NSString stringWithFormat:@"%ld.aac", (NSInteger)[NSDate timeIntervalSinceReferenceDate]];
    NSString *audioFile = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileName];
    [[NSFileManager defaultManager] removeItemAtPath:audioFile error:nil];
    [[NSFileManager defaultManager] createFileAtPath:audioFile contents:nil attributes:nil];
    self.audioFileHandle = [NSFileHandle fileHandleForWritingAtPath:audioFile];
    [self.manager startCapture];
}

- (void)stopRecordingAndCloseFile {
    [self.audioFileHandle closeFile];
    self.audioFileHandle = nil;
    [self.manager stopCapture];
}

- (void)showAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"编码器初始化失败" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - delegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    __weak typeof(self) ws = self;
    [self.encoder encodeSampleBuffer:sampleBuffer completionBlock:^(NSData *encodedData, NSError *error) {
        __strong typeof(self) ss = ws;
        [ss.audioFileHandle writeData:encodedData];
    }];
}

@end
