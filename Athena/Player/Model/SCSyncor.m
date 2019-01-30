//
//  SCSyncor.m
//  Athena
//
//  Created by Theresa on 2019/01/30.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCSyncor.h"

@interface SCSyncor ()

//@property (nonatomic, assign) NSTimeInterval videoFrameStartTime;
//@property (nonatomic, assign) NSTimeInterval videoFrameDuration;

@property (assign, readwrite) NSTimeInterval audioFrameStartTime;
@property (assign, readwrite) NSTimeInterval audioFramePosition;

@end

@implementation SCSyncor

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)updateAudioClock:(NSTimeInterval)frameStartTime position:(NSTimeInterval)position {
    self.audioFrameStartTime = frameStartTime;
    self.audioFramePosition  = position;
}

- (BOOL)shouldRenderVideoFrame:(NSTimeInterval)position duration:(NSTimeInterval)duration {
    NSTimeInterval time = [NSDate date].timeIntervalSince1970;
    if (self.audioFramePosition + time - self.audioFrameStartTime >= position + duration) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)checkShouldDiscardVideoFrame:(NSTimeInterval)position duration:(NSTimeInterval)duration {
    if (fabs(self.audioFramePosition - position) > 0.1) {
        return YES;
    } else {
        return NO;
    }
}

@end
