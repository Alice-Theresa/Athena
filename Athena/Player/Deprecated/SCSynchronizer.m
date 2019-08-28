//
//  SCSynchronizer.m
//  Athena
//
//  Created by Theresa on 2019/01/30.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCSynchronizer.h"

@interface SCSynchronizer ()

@property (nonatomic, assign) NSTimeInterval audioFramePlayTime;
@property (nonatomic, assign) NSTimeInterval audioFramePosition;

@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, assign) NSUInteger lockCounter;

@end

@implementation SCSynchronizer

- (instancetype)init {
    if (self = [super init]) {
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)updateAudioClock:(NSTimeInterval)position {
//    if (!self.isBlock) {
        self.audioFramePlayTime = [NSDate date].timeIntervalSince1970;
        self.audioFramePosition = position;
//    }
}

- (BOOL)shouldRenderVideoFrame:(NSTimeInterval)position duration:(NSTimeInterval)duration {
//    if (self.isBlock) {
//        return NO;
//    }
    NSTimeInterval time = [NSDate date].timeIntervalSince1970;
    if (self.audioFramePosition + time - self.audioFramePlayTime >= position + duration) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)shouldDiscardVideoFrame:(NSTimeInterval)position duration:(NSTimeInterval)duration {
    if (fabs(self.audioFramePosition - position) > 0.1) {
        return YES;
    } else {
        return NO;
    }
}


@end
