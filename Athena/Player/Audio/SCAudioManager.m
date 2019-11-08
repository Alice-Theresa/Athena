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

@interface SCAudioManager ()

{
    AUGraph _graph;
    AUNode _mixerNode;
    AUNode _outputNode;
    AUNode _timePitchNode;
    AudioUnit _mixerUnit;
    AudioUnit _outputUnit;
    AudioUnit _timePitchUnit;
}

@property (nonatomic, strong) AVAudioSession *audioSession;
//@property (nonatomic, assign) AudioUnit audioUnit;
@property (nonatomic) AudioStreamBasicDescription asbd;
@property (nonatomic) float rate;

@property (nonatomic) float volume;
@end

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
//        _audioSession = [AVAudioSession sharedInstance];
//        [_audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        [self initPlayer];
    }
    return self;
}

+ (AudioComponentDescription)mixerACD
{
    AudioComponentDescription acd;
    acd.componentType = kAudioUnitType_Mixer;
    acd.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    return acd;
}

+ (AudioComponentDescription)outputACD
{
    AudioComponentDescription acd;
    acd.componentType = kAudioUnitType_Output;
    acd.componentSubType = kAudioUnitSubType_RemoteIO;
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    return acd;
}

+ (AudioComponentDescription)timePitchACD
{
    AudioComponentDescription acd;
    acd.componentType = kAudioUnitType_FormatConverter;
    acd.componentSubType = kAudioUnitSubType_NewTimePitch;
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    return acd;
}

+ (AudioStreamBasicDescription)commonASBD
{
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

- (void)initPlayer {
    AudioStreamBasicDescription asbd = [self.class commonASBD];
    AudioComponentDescription mixerACD = [self.class mixerACD];
    AudioComponentDescription outputACD = [self.class outputACD];
    AudioComponentDescription timePitchACD = [self.class timePitchACD];

    NewAUGraph(&_graph);
    AUGraphAddNode(_graph, &mixerACD, &_mixerNode);
    AUGraphAddNode(_graph, &outputACD, &_outputNode);
    AUGraphAddNode(_graph, &timePitchACD, &_timePitchNode);

    AUGraphOpen(_graph);
    AUGraphNodeInfo(_graph, _mixerNode, &mixerACD, &_mixerUnit);
    AUGraphNodeInfo(_graph, _outputNode, &outputACD, &_outputUnit);
    AUGraphNodeInfo(_graph, _timePitchNode, &timePitchACD, &_timePitchUnit);

    UInt32 value = 4096;
    UInt32 size = sizeof(value);
    AudioUnitScope scope = kAudioUnitScope_Global;
    AudioUnitPropertyID param = kAudioUnitProperty_MaximumFramesPerSlice;
    AudioUnitSetProperty(_mixerUnit, param, scope, 0, &value, size);
    AudioUnitSetProperty(_outputUnit, param, scope, 0, &value, size);
    AudioUnitSetProperty(_timePitchUnit, param, scope, 0, &value, size);

    AURenderCallbackStruct inputCallbackStruct;
    inputCallbackStruct.inputProc = inputCallback;
    inputCallbackStruct.inputProcRefCon = (__bridge void *)self;
    AUGraphSetNodeInputCallback(_graph, _mixerNode, 0, &inputCallbackStruct);
//    AudioUnitAddRenderNotify(_outputUnit, outputCallback, (__bridge void *)self);

    [self setRate:1];
    [self setVolume:1];
    [self setAsbd:asbd];

    AUGraphInitialize(_graph);
}

- (void)disconnectNodeInput:(AUNode)sourceNode destNode:(AUNode)destNode {
    UInt32 count = 8;
    AUNodeInteraction interactions[8];
    if (AUGraphGetNodeInteractions(_graph, destNode, &count, interactions) == noErr) {
        for (UInt32 i = 0; i < MIN(count, 8); i++) {
            AUNodeInteraction interaction = interactions[i];
            if (interaction.nodeInteractionType == kAUNodeInteraction_Connection) {
                AUNodeConnection connection = interaction.nodeInteraction.connection;
                if (connection.sourceNode == sourceNode) {
                    AUGraphDisconnectNodeInput(_graph, connection.destNode, connection.destInputNumber);
                    break;
                }
            }
        }
    }
}

- (void)setVolume:(float)volume {
    AudioUnitParameterID param = kMultiChannelMixerParam_Volume;
    if (AudioUnitSetParameter(_mixerUnit, param, kAudioUnitScope_Input, 0, volume, 0) == noErr) {
        _volume = volume;
    }
}


- (void)setRate:(float)rate {
    if (_rate == rate) {
        return;
    }
    if (AudioUnitSetParameter(_timePitchUnit, kNewTimePitchParam_Rate, kAudioUnitScope_Global, 0, rate, 0) == noErr) {
        if (_rate == 1.0 || rate == 1.0) {
            if (rate == 1.0) {
                [self disconnectNodeInput:_mixerNode destNode:_timePitchNode];
                [self disconnectNodeInput:_timePitchNode destNode:_outputNode];
                AUGraphConnectNodeInput(_graph, _mixerNode, 0, _outputNode, 0);
            } else {
                [self disconnectNodeInput:_mixerNode destNode:_outputNode];
                AUGraphConnectNodeInput(_graph, _mixerNode, 0, _timePitchNode, 0);
                AUGraphConnectNodeInput(_graph, _timePitchNode, 0, _outputNode, 0);
            }
            AUGraphUpdate(_graph, NULL);
        }
        _rate = rate;
    }
}

- (void)setAsbd:(AudioStreamBasicDescription)asbd {
    UInt32 size = sizeof(AudioStreamBasicDescription);
    AudioUnitPropertyID param = kAudioUnitProperty_StreamFormat;
    if (AudioUnitSetProperty(_mixerUnit, param, kAudioUnitScope_Global, 0, &asbd, size) == noErr &&
        AudioUnitSetProperty(_outputUnit, param, kAudioUnitScope_Input, 0, &asbd, size) == noErr &&
        AudioUnitSetProperty(_timePitchUnit, param, kAudioUnitScope_Global, 0, &asbd, size) == noErr) {
        _asbd = asbd;
    } else {
        AudioUnitSetProperty(_mixerUnit, param, kAudioUnitScope_Global, 0, &_asbd, size);
        AudioUnitSetProperty(_outputUnit, param, kAudioUnitScope_Input, 0, &_asbd, size);
        AudioUnitSetProperty(_timePitchUnit, param, kAudioUnitScope_Global, 0, &_asbd, size);
    }
}

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

- (void)play {
    AUGraphStart(_graph);//AudioOutputUnitStart(self.audioUnit);
}

- (void)stop {
    AUGraphStop(_graph);//AudioOutputUnitStop(self.audioUnit);
}

@end
