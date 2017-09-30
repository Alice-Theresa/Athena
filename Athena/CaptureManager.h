//
//  CaptureManager.h
//  Athena
//
//  Created by Theresa on 2017/9/30.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CaptureManager : NSObject

+ (instancetype)shared;

- (void)settingAudioSession;
- (void)addAudioInputOutput:(id<AVCaptureAudioDataOutputSampleBufferDelegate>)delegate;

- (void)startCapture;
- (void)stopCapture;

@end
