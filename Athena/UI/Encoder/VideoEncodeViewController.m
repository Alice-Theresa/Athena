//
//  VideoEncodeViewController.m
//  Athena
//
//  Created by Theresa on 2017/10/19.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "VideoEncodeViewController.h"
#import "VideoCaptureManager.h"
#import "H264HardwareEncoder.h"
#import "H264EncoderDelegate.h"
#import "SharedQueue.h"

@interface VideoEncodeViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, H264EncoderDelegate>

@property (nonatomic, strong) VideoCaptureManager *manager;
@property (nonatomic, strong) H264HardwareEncoder *encoder;
@property (nonatomic, strong) NSFileHandle *videoFileHandle;

@end

@implementation VideoEncodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"H264编码";
    self.manager = [VideoCaptureManager shared];
    [self.manager addVideoInputOutput:self];
    
    self.encoder = [[H264HardwareEncoder alloc] initWithEncoderQueue:[SharedQueue videoEncode] callbackQueue:[SharedQueue videoCallback]];
    self.encoder.delegate = self;
    
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:[self.manager currentCaptureSession]];
    previewLayer.frame = self.view.bounds;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:previewLayer];
    
    NSString *fileName = [NSString stringWithFormat:@"%ld.h264", (NSInteger)[NSDate timeIntervalSinceReferenceDate]];
    NSString *videoFile = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileName];
    [[NSFileManager defaultManager] removeItemAtPath:videoFile error:nil];
    [[NSFileManager defaultManager] createFileAtPath:videoFile contents:nil attributes:nil];
    self.videoFileHandle = [NSFileHandle fileHandleForWritingAtPath:videoFile];
    
    [self.manager startCapture];

}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.manager stopCapture];
    [self.manager clearCapture];
    [self.videoFileHandle closeFile];
    self.videoFileHandle = nil;
}

#pragma mark - delegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    [self.encoder encodeSampleBuffer:sampleBuffer];
}

- (void)encodedResult:(NSData *)data error:(NSError *)error {
    if (self.videoFileHandle) {
        [self.videoFileHandle writeData:data];
    }
}

@end
