//
//  SCAudioManager.m
//  Athena
//
//  Created by Theresa on 2019/01/10.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Accelerate/Accelerate.h>
#import <AVFoundation/AVFoundation.h>
#import "SCAudioManager.h"

static OSStatus inputCallback(void *inRefCon,
                             AudioUnitRenderActionFlags *ioActionFlags,
                             const AudioTimeStamp *inTimeStamp,
                             UInt32 inBusNumber,
                             UInt32 inNumberFrames,
                             AudioBufferList *ioData) {
    @autoreleasepool {
        SCAudioManager *player = (__bridge SCAudioManager *)inRefCon;
        [player.delegate fetchoutputData:ioData numberOfFrames:inNumberFrames];
    }
    return noErr;
}

@interface SCAudioManager ()

@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, assign) AudioUnit audioUnit;

@end

@implementation SCAudioManager

+ (AudioStreamBasicDescription)commonASBD {
    UInt32 byteSize = sizeof(float);
    AudioStreamBasicDescription asbd;
    asbd.mBitsPerChannel   = byteSize * 8;
    asbd.mBytesPerFrame    = byteSize;
    asbd.mChannelsPerFrame = 2;
    asbd.mFormatFlags      = kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved;
    asbd.mFormatID         = kAudioFormatLinearPCM;
    asbd.mFramesPerPacket  = 1;
    asbd.mBytesPerPacket   = asbd.mFramesPerPacket * asbd.mBytesPerFrame;
    asbd.mSampleRate       = 44100.0f;
    return asbd;
}

+ (AudioComponentDescription)outputACD {
    AudioComponentDescription acd;
    acd.componentType         = kAudioUnitType_Output;
    acd.componentSubType      = kAudioUnitSubType_RemoteIO;
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    return acd;
}

+ (instancetype)shared {
    static SCAudioManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SCAudioManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _audioSession = [AVAudioSession sharedInstance];
        [_audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        [self initPlayer];
    }
    return self;
}

- (void)initPlayer {
    
    OSStatus status = noErr;
    
    AudioComponentDescription audioDesc = [self.class outputACD];
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &audioDesc);
    AudioComponentInstanceNew(inputComponent, &_audioUnit);
    
    AudioStreamBasicDescription absd = [self.class commonASBD];
    
    status = AudioUnitSetProperty(self.audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  0,
                                  &absd,
                                  sizeof(absd));
    if (status) {
        NSLog(@"AudioUnitSetProperty eror with status:%d", status);
    }
    
    AURenderCallbackStruct playCallback;
    playCallback.inputProc = inputCallback;
    playCallback.inputProcRefCon = (__bridge void *)self;
    AudioUnitSetProperty(self.audioUnit,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Input,
                         0,
                         &playCallback,
                         sizeof(playCallback));
    
    
    status = AudioUnitInitialize(self.audioUnit);
    NSLog(@"result %d", status);
}

- (void)play {
    AudioOutputUnitStart(self.audioUnit);
}

- (void)stop {
    AudioOutputUnitStop(self.audioUnit);
}

@end
