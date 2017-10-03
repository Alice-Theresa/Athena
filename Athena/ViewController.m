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
#import "AACEncoder.h"

@interface ViewController () <AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) CaptureManager *manager;
@property (nonatomic, strong) NSFileHandle *audioFileHandle;
@property (nonatomic, strong) AACEncoder *encoder;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.encoder = [[AACEncoder alloc] init];
    self.manager = [CaptureManager shared];
    [self.manager settingAudioSession];
    [self.manager addAudioInputOutput:self];
}

- (IBAction)recordingOrNot:(id)sender {
    UISwitch *switcher = sender;
    if (switcher.isOn) {
        NSString *audioFile = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"abc.aac"];
        [[NSFileManager defaultManager] removeItemAtPath:audioFile error:nil];
        [[NSFileManager defaultManager] createFileAtPath:audioFile contents:nil attributes:nil];
        self.audioFileHandle = [NSFileHandle fileHandleForWritingAtPath:audioFile];
        [self.manager startCapture];
    } else {
        [self.audioFileHandle closeFile];
        self.audioFileHandle = nil;
        [self.manager stopCapture];
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
