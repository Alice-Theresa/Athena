//
//  AACEncoder.m
//  Athena
//
//  Created by Theresa on 2017/9/30.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "AACEncoder.h"

@implementation AACEncoder

- (void)setupEncoderForOutput:(CMSampleBufferRef)sampleBuffer {
    CMFormatDescriptionRef inputFormat = CMSampleBufferGetFormatDescription(sampleBuffer);
    const AudioStreamBasicDescription *inputASBD = CMAudioFormatDescriptionGetStreamBasicDescription(inputFormat);
    
    AudioStreamBasicDescription outputASBD = {0};
    outputASBD.mFormatID = kAudioFormatMPEG4AAC;
    outputASBD.mSampleRate = inputASBD->mSampleRate;
    outputASBD.mBitsPerChannel = inputASBD->mBitsPerChannel;
    outputASBD.mFramesPerPacket = 1;
    outputASBD.mBytesPerFrame = 2;
    outputASBD.mBytesPerPacket = 2;
    outputASBD.mChannelsPerFrame = 1;
    outputASBD.mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsNonInterleaved;
    outputASBD.mReserved = 0;
    
    //todo
}

- (AudioClassDescription *)getAudioClassDescriptionWithType:(UInt32)type fromManufacturer:(UInt32)manufacturer {
    static AudioClassDescription desc;
    
    UInt32 encoderSpecifier = type;
    OSStatus st;
    
    UInt32 size;
    st = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size);
    if (st) {
        NSLog(@"error getting audio format propery info: %d", (int)(st));
        return nil;
    }
    
    unsigned int count = size / sizeof(AudioClassDescription);
    AudioClassDescription descriptions[count];
    st = AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size, descriptions);
    if (st) {
        NSLog(@"error getting audio format propery: %d", (int)(st));
        return nil;
    }
    
    for (unsigned int i = 0; i < count; i++) {
        if ((type == descriptions[i].mSubType) &&
            (manufacturer == descriptions[i].mManufacturer)) {
            memcpy(&desc, &(descriptions[i]), sizeof(desc));
            return &desc;
        }
    }
    return nil;
}

@end
