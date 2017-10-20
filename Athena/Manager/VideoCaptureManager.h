//
//  VideoCaptureManager.h
//  Athena
//
//  Created by Theresa on 2017/10/19.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoCaptureManager : NSObject

+ (instancetype)shared;

- (void)addVideoInputOutput:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)delegate;

- (AVCaptureSession *)currentCaptureSession;
- (void)clearCapture;
- (void)startCapture;
- (void)stopCapture;

@end
