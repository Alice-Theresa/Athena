//
//  CaptureManager.h
//  Athena
//
//  Created by Theresa on 2017/9/30.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioCaptureManager : NSObject

+ (instancetype)shared;

- (void)settingAudioSession;
- (void)addAudioInputOutput:(id<AVCaptureAudioDataOutputSampleBufferDelegate>)delegate;

- (void)clearCapture;
- (void)startCapture;
- (void)stopCapture;

@end
