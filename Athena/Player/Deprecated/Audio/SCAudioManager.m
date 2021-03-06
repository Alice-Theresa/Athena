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
    float *_outData;
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
        _outData = (float *)calloc(max_frame_size * max_chan, sizeof(float));
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
    
    //audio property
   /* UInt32 flag = 1;
    if (flag) {
        status = AudioUnitSetProperty(self.audioUnit,
                                      kAudioOutputUnitProperty_EnableIO,
                                      kAudioUnitScope_Output,
                                      OUTPUT_BUS,
                                      &flag,
                                      sizeof(flag));
    }
    if (status) {
        NSLog(@"AudioUnitSetProperty error with status:%d", status);
    }*/
    
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
    for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; iBuffer++) {
        memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
    }
    SCAudioManager *player = (__bridge SCAudioManager *)inRefCon;
    [player.delegate fetchoutputData:player->_outData numberOfFrames:inNumberFrames numberOfChannels:2];

    float scale = (float)INT16_MAX;
    vDSP_vsmul(player->_outData, 1, &scale, player->_outData, 1, inNumberFrames * 2);
    
    for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; iBuffer++) {
        int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
        for (int iChannel = 0; iChannel < thisNumChannels; iChannel++) {
            vDSP_vfix16(player->_outData + iChannel,
                        2,
                        (SInt16 *)ioData->mBuffers[iBuffer].mData + iChannel,
                        thisNumChannels,
                        inNumberFrames);
        }
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
