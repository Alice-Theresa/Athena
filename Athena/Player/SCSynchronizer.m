//
//  SCSynchronizer.m
//  Athena
//
//  Created by Theresa on 2019/01/30.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCSynchronizer.h"
#import "SCAudioFrame.h"

@interface SCSynchronizer ()

//@property (nonatomic, assign) NSTimeInterval videoFrameStartTime;
//@property (nonatomic, assign) NSTimeInterval videoFrameDuration;

@property (assign, readwrite) NSTimeInterval audioFrameStartTime;
@property (assign, readwrite) NSTimeInterval audioFramePosition;

@end

@implementation SCSynchronizer

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)updateAudioClock {
    if (self.audioFrame) {
        self.audioFrameStartTime = [NSDate date].timeIntervalSince1970;
        self.audioFramePosition  = self.audioFrame.position;
    }
}

- (BOOL)shouldRenderVideoFrameOrNot {
    NSTimeInterval time = [NSDate date].timeIntervalSince1970;
    if (self.audioFramePosition + time - self.audioFrameStartTime >= self.videoFrame.position + self.videoFrame.duration) {
        return YES;
    } else {
        return NO;
    }
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
