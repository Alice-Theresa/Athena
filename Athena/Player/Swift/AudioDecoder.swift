//
//  AudioDecoder.swift
//  Athena
//
//  Created by Theresa on 2019/2/4.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation
import Accelerate

@objc class AudioDecoder: NSObject {
    
    let _samplingRate: Int32 = 44100
    let _channelCount: Int32 = 2
    
    var temp_frame: UnsafeMutablePointer<AVFrame>?
    var audio_swr_context: OpaquePointer?
    
    var _audio_swr_buffer: UnsafeMutableRawPointer?
    var _audio_swr_buffer_size: Int = 0
    
    weak var context: SCFormatContext?
    var codecContext: UnsafeMutablePointer<AVCodecContext>?
    
    deinit {
        av_frame_free(&temp_frame)
        swr_free(&audio_swr_context)
    }
    
    @objc init(formatContext: SCFormatContext) {
        context = formatContext
        temp_frame = av_frame_alloc()
        codecContext = formatContext.audioCodecContext
        super.init()
        setupSwsContext()
    }
    
    func setupSwsContext() {
        guard let codec = codecContext else { return }
        audio_swr_context = swr_alloc_set_opts(nil,
                                               av_get_default_channel_layout(_channelCount),
                                               AV_SAMPLE_FMT_S16,
                                               _samplingRate,
                                               av_get_default_channel_layout(codec.pointee.channels),
                                               codec.pointee.sample_fmt,
                                               codec.pointee.sample_rate,
                                               0,
                                               nil)
        let result = swr_init(audio_swr_context)
        if result < 0 {
            swr_free(&audio_swr_context)
        }
        if let _ = audio_swr_context {
            swr_free(&audio_swr_context)
        }
    }
    
    @objc func decode(packet: AVPacket) -> NSArray {
        var packet = packet
        let defaultArray = NSArray()
        let array = NSMutableArray()
        guard let _ = packet.data, let context = context else { return defaultArray }
        var result = avcodec_send_packet(context.videoCodecContext, &packet)
        if result < 0 {
            return defaultArray
        }
        while result >= 0 {
            result = avcodec_receive_frame(context.videoCodecContext, temp_frame)
            if result < 0 {
                // todo
                break
            } else {
                if let frame = audioFrameFromTempFrame(packetSize: Int(packet.size)) {
                    array.add(frame)
                }
            }
        }
        av_packet_unref(&packet)
        return array.copy() as! NSArray
    }
    
    func audioFrameFromTempFrame(packetSize: Int) -> AudioFrame?  {
        fatalError()
        guard let temp = temp_frame, let _ = temp.pointee.data.0  else { return nil }
        var numberOfFrames: Int
        var audioDataBuffer: UnsafeMutableRawPointer?
        if let context = audio_swr_context {
            let ratio = max(1, _samplingRate / codecContext!.pointee.sample_rate) * max(1, _channelCount / codecContext!.pointee.channels) * 2
            let buffer_size = av_samples_get_buffer_size(nil, _channelCount, temp.pointee.nb_samples * ratio, AV_SAMPLE_FMT_S16, 1)
            if _audio_swr_buffer == nil || _audio_swr_buffer_size < buffer_size {
                _audio_swr_buffer_size = Int(buffer_size)
                _audio_swr_buffer = realloc(_audio_swr_buffer!, _audio_swr_buffer_size)
            }
            let outyput_buffer = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>.allocate(capacity: 1)
            
            let dataPointer = withUnsafeMutablePointer(to: &temp_frame!.pointee.data){$0}.withMemoryRebound(to: Optional<UnsafePointer<UInt8>>.self, capacity: MemoryLayout<UnsafePointer<UInt8>>.stride * 8) {$0}
            numberOfFrames = Int(swr_convert(audio_swr_context,
                                             outyput_buffer,
                                             temp_frame!.pointee.nb_samples * ratio,
                                             dataPointer,
                                             temp_frame!.pointee.nb_samples))
            audioDataBuffer = _audio_swr_buffer
            
        }
        let position = TimeInterval(av_frame_get_best_effort_timestamp(temp_frame!)) * context!.audioTimebase
        let duration = TimeInterval(av_frame_get_pkt_duration(temp_frame!)) * context!.audioTimebase
        let audioFrame = AudioFrame(position: position, duration: duration)
        
        let numberOfElements = numberOfFrames * Int(_channelCount)
        audioFrame.setting(samplesLength: numberOfElements * MemoryLayout.size(ofValue: Float.self))
        
        var scale = 1.0 / Float(Int16.max)
//        vDSP_vflt16(audioDataBuffer,
//                    1,
//                    audioFrame.pointee.samples,
//                    1,
//                    numberOfElements)
//        vDSP_vsmul(audioFrame.samples!,
//                   1,
//                   &scale,
//                   audioFrame.samples!,
//                   1,
//                   vDSP_Length(numberOfElements))
        return audioFrame
    }

}
