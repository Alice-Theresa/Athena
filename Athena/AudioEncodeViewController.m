//
//  ViewController.m
//  Athena
//
//  Created by Theresa on 2017/9/30.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "AACEncoderProtocol.h"
#import "AudioEncodeViewController.h"
#import "SharedQueue.h"

#import "CaptureManager.h"
#import "AACHardEncoder.h"
#import "AACSoftEncoder.h"

@interface AudioEncodeViewController () <AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) CaptureManager *manager;
@property (nonatomic, strong) NSFileHandle *audioFileHandle;
@property (nonatomic, strong) id<AACEncoderProtocol> encoder;
@property (weak, nonatomic) IBOutlet UISwitch *encoderSwitch;

@end

@implementation AudioEncodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"AAC编码";
    self.encoder = [[AACHardEncoder alloc] initWithEncoderQueue:[SharedQueue audioEncode] callbackQueue:[SharedQueue audioCallback]];
    self.manager = [CaptureManager shared];
    [self.manager settingAudioSession];
    [self.manager addAudioInputOutput:self];
    
}

- (IBAction)recordingOrNot:(id)sender {
    UISwitch *switcher = sender;
    if (switcher.isOn) {
        self.encoderSwitch.enabled = NO;
        NSString *fileName = [NSString stringWithFormat:@"%f.aac", [NSDate timeIntervalSinceReferenceDate]];
        NSString *audioFile = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileName];
        [[NSFileManager defaultManager] removeItemAtPath:audioFile error:nil];
        [[NSFileManager defaultManager] createFileAtPath:audioFile contents:nil attributes:nil];
        self.audioFileHandle = [NSFileHandle fileHandleForWritingAtPath:audioFile];
        [self.manager startCapture];
    } else {
        self.encoderSwitch.enabled = YES;
        [self.audioFileHandle closeFile];
        self.audioFileHandle = nil;
        [self.manager stopCapture];
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
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"编码器初始化失败" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    __weak typeof(self) ws = self;
    [self.encoder encodeSampleBuffer:sampleBuffer completionBlock:^(NSData *encodedData, NSError *error) {
        __strong typeof(self) ss = ws;
        [ss.audioFileHandle writeData:encodedData];
    }];
}

@end
