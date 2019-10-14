//
//  SCAudioManager.m
//  Athena
//
//  Created by Theresa on 2019/01/10.
//  Copyright © 2019 Theresa. All rights reserved.
//

#define OUTPUT_BUS 0

#import <Accelerate/Accelerate.h>
#import <AVFoundation/AVFoundation.h>
#import "SCAudioManager.h"

@interface SCAudioManager () {
    SInt16 *_outData;
}

@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, assign) AudioUnit audioUnit;

@end

static int const max_frame_size = 4096;
static int const max_chan = 2;

@implementation SCAudioManager

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
        _outData = (SInt16 *)calloc(8192, sizeof(SInt16));//(float *)calloc(max_frame_size * max_chan, sizeof(float));
        [self initPlayer];
    }
    return self;
}

- (void)initPlayer {
    
    OSStatus status = noErr;
    
    AudioComponentDescription audioDesc;
    audioDesc.componentType = kAudioUnitType_Output;
    audioDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    audioDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    audioDesc.componentFlags = 0;
    audioDesc.componentFlagsMask = 0;
    
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &audioDesc);
    AudioComponentInstanceNew(inputComponent, &_audioUnit);
    
    // format
    AudioStreamBasicDescription outputFormat;
    memset(&outputFormat, 0, sizeof(outputFormat));
    outputFormat.mSampleRate       = 44100; // 采样率
    outputFormat.mFormatID         = kAudioFormatLinearPCM; // PCM格式
    outputFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger; // 整形
    outputFormat.mFramesPerPacket  = 1; // 每帧只有1个packet
    outputFormat.mChannelsPerFrame = 2; // 声道数
    outputFormat.mBytesPerFrame    = 4; // 每帧只有2个byte 声道*位深*Packet数
    outputFormat.mBytesPerPacket   = 4; // 每个Packet只有2个byte
    outputFormat.mBitsPerChannel   = 16; // 位深
    
    status = AudioUnitSetProperty(self.audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  OUTPUT_BUS,
                                  &outputFormat,
                                  sizeof(outputFormat));
    if (status) {
        NSLog(@"AudioUnitSetProperty eror with status:%d", status);
    }
    
    
    // callback
    AURenderCallbackStruct playCallback;
    playCallback.inputProc = PlayCallback;
    playCallback.inputProcRefCon = (__bridge void *)self;
    AudioUnitSetProperty(self.audioUnit,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Input,
                         OUTPUT_BUS,
                         &playCallback,
                         sizeof(playCallback));
    
    
    OSStatus result = AudioUnitInitialize(self.audioUnit);
    NSLog(@"result %d", result);
}



static OSStatus PlayCallback(void *inRefCon,
                             AudioUnitRenderActionFlags *ioActionFlags,
                             const AudioTimeStamp *inTimeStamp,
                             UInt32 inBusNumber,
                             UInt32 inNumberFrames,
                             AudioBufferList *ioData) {
    SCAudioManager *player = (__bridge SCAudioManager *)inRefCon;
    [player.delegate fetchoutputData:player->_outData numberOfFrames:inNumberFrames numberOfChannels:2];
    for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
        memcpy((SInt16 *)ioData->mBuffers[iBuffer].mData, player->_outData, ioData->mBuffers[iBuffer].mDataByteSize);
    }
    return noErr;
}

- (void)play {
    AudioOutputUnitStart(self.audioUnit);
}

- (void)stop {
    AudioOutputUnitStop(self.audioUnit);
}


@end
