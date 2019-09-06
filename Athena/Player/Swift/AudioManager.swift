//
//  AudioManager.swift
//  Athena
//
//  Created by Theresa on 2019/2/6.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation
import AVFoundation
import Accelerate

protocol AudioManagerDelegate: NSObjectProtocol {
    func fetch(outputData: UnsafeMutablePointer<Float>, numberOfFrames: UInt32, numberOfChannels: UInt32)
}

class AudioManager {
    weak var delegate: AudioManagerDelegate?
    var outData = UnsafeMutablePointer<Float>.allocate(capacity: 4096 * 2)
    
    var audioUnit: AudioUnit!
    let audioSession = AVAudioSession.sharedInstance()
    
    var callback: AURenderCallback = {(
        inRefCon: UnsafeMutableRawPointer,
        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
        inTimeStamp: UnsafePointer<AudioTimeStamp>,
        inBusNumber: UInt32,
        inNumberFrames:UInt32,
        ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus in
        
        if let ioData = ioData {
            for iBuffer in 0..<Int(ioData.pointee.mNumberBuffers) {
                memset(ioData[iBuffer].mBuffers.mData, 0, Int(ioData[iBuffer].mBuffers.mDataByteSize))
            }
            let player = Unmanaged<AudioManager>.fromOpaque(inRefCon).takeUnretainedValue()
            if let delegate = player.delegate {
                delegate.fetch(outputData: player.outData, numberOfFrames: inNumberFrames, numberOfChannels: 2)
                YuuAudioAccelerateCompute(player.outData, inNumberFrames, ioData)
                return noErr
            }
        }
        return noErr
    }
    
    init() {
        do {
            try audioSession.setPreferredSampleRate(44_100)
            // https://stackoverflow.com/questions/51010390/avaudiosession-setcategory-swift-4-2-ios-12-play-sound-on-silent
            if #available(iOS 10.0, *) {
                try audioSession.setCategory(.playback, mode: .default, options: [])
            } else {
                audioSession.perform(NSSelectorFromString("setCategory:withOptions:error:"), with: AVAudioSession.Category.playAndRecord, with:  [AVAudioSession.CategoryOptions.defaultToSpeaker])
            }
            try audioSession.setActive(true)
        } catch {
            fatalError()
        }
        initPlayer()
    }
    
    func initPlayer() {
        var audioDesc = AudioComponentDescription(componentType: kAudioUnitType_Output,
                                                  componentSubType: kAudioUnitSubType_RemoteIO,
                                                  componentManufacturer: kAudioUnitManufacturer_Apple,
                                                  componentFlags: 0,
                                                  componentFlagsMask: 0)
        guard let inputComponent = AudioComponentFindNext(nil, &audioDesc) else { return }
        AudioComponentInstanceNew(inputComponent, &audioUnit)
        
        var outputFormat = AudioStreamBasicDescription(mSampleRate: 44100,
                                                       mFormatID: kAudioFormatLinearPCM,
                                                       mFormatFlags: kLinearPCMFormatFlagIsSignedInteger,
                                                       mBytesPerPacket: 4,
                                                       mFramesPerPacket: 1,
                                                       mBytesPerFrame: 4,
                                                       mChannelsPerFrame: 2,
                                                       mBitsPerChannel: 16,
                                                       mReserved: 0)
        var result = AudioUnitSetProperty(audioUnit,
                                          kAudioUnitProperty_StreamFormat,
                                          kAudioUnitScope_Input,
                                          0,
                                          &outputFormat,
                                          UInt32(MemoryLayout.size(ofValue: outputFormat)))
        var callbackStruct = AURenderCallbackStruct()
        callbackStruct.inputProc = callback
        callbackStruct.inputProcRefCon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        result = AudioUnitSetProperty(audioUnit,
                                      kAudioUnitProperty_SetRenderCallback,
                                      kAudioUnitScope_Input,
                                      0,
                                      &callbackStruct,
                                      UInt32(MemoryLayout<AURenderCallbackStruct>.size));
        result = AudioUnitInitialize(audioUnit)
    }
    
    func play() {
        AudioOutputUnitStart(audioUnit)
    }

    func stop() {
        AudioOutputUnitStop(audioUnit)
    }
}
