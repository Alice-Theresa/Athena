//
//  AudioPlayerManager.m
//  Athena
//
//  Created by Theresa on 2018/9/28.
//  Copyright © 2018年 Theresa. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "AudioPlayerManager.h"

@interface AudioPlayerManager()

@property (nonatomic, strong) AVAudioSession *audioSession;

@end

@implementation AudioPlayerManager

+ (instancetype)shared {
    static AudioPlayerManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[AudioPlayerManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _audioSession = [AVAudioSession sharedInstance];
    }
    return self;
}

- (void)settingMode {
    [self.audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
}

@end
