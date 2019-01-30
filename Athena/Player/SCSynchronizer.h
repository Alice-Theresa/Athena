//
//  SCSynchronizer.h
//  Athena
//
//  Created by Theresa on 2019/01/30.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCFrame;
@class SCAudioFrame;

NS_ASSUME_NONNULL_BEGIN

@interface SCSynchronizer : NSObject

@property (nonatomic, strong, nullable) SCFrame *videoFrame;
@property (nonatomic, strong, nullable) SCAudioFrame *audioFrame;

- (void)updateAudioClock;
- (BOOL)shouldRenderVideoFrameOrNot;

- (BOOL)shouldRenderVideoFrame:(NSTimeInterval)position duration:(NSTimeInterval)duration;
- (BOOL)checkShouldDiscardVideoFrame:(NSTimeInterval)position duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
