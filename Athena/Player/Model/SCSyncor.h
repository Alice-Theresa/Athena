//
//  SCSyncor.h
//  Athena
//
//  Created by Theresa on 2019/01/30.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCFrame;
@class SCAudioFrame;

NS_ASSUME_NONNULL_BEGIN

@interface SCSyncor : NSObject

- (void)updateAudioClock:(NSTimeInterval)frameStartTime position:(NSTimeInterval)position;
- (BOOL)shouldRenderVideoFrame:(NSTimeInterval)position duration:(NSTimeInterval)duration;
- (BOOL)checkShouldDiscardVideoFrame:(NSTimeInterval)position duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
