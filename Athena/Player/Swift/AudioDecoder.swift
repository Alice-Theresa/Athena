//
//  AudioDecoder.swift
//  Athena
//
//  Created by Theresa on 2019/2/4.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation
import Accelerate

class AudioDecoder: NSObject {
    
    let _samplingRate: Int32 = 44100
    let _channelCount: Int32 = 2
    
    var temp_frame: YuuFrame?
    var audio_swr_context: OpaquePointer?
    
    var _audio_swr_buffer: UnsafeMutableRawPointer?
    var _audio_swr_buffer_size: Int = 0
    
    weak var context: FormatContext?
    var codecContext: UnsafeMutablePointer<AVCodecContext>?
    
    deinit {
//        av_frame_free(&temp_frame)
        swr_free(&audio_swr_context)
    }
    
    init(formatContext: FormatContext) {
        context = formatContext
        temp_frame = YuuFrame()
        codecContext = formatContext.audioCodecContext?.cContextPtr
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
        if result < 0 || audio_swr_context == nil {
            if let _ = audio_swr_context {
                swr_free(&audio_swr_context)
            }
        }
    }
    
    func decode(packet: YuuPacket) -> NSArray {
        let defaultArray = NSArray()
        let array = NSMutableArray()
        guard let _ = packet.data, let context = context else { return defaultArray }
        var result = avcodec_send_packet(context.audioCodecContext?.cContextPtr, packet.cPacketPtr)
        if result < 0 {
            return defaultArray
        }
        while result >= 0 {
            result = avcodec_receive_frame(context.audioCodecContext?.cContextPtr, temp_frame?.cFramePtr)
            if result < 0 {
                break
            }
            if let frame = audioFrameFromTempFrame(packetSize: Int(packet.size)) {
                array.add(frame)
            }
        }
        packet.unref()
        return array.copy() as! NSArray
    }
    
    func audioFrameFromTempFrame(packetSize: Int) -> AudioFrame?  {
        
        guard let temp = temp_frame, let _ = temp.data[0], let codecContext = codecContext else { return nil }
        var numberOfFrames: Int32 = 0
        var audioDataBuffer: UnsafeMutableRawPointer?
        if let c = audio_swr_context {
            let ratio = max(1, _samplingRate / codecContext.pointee.sample_rate) * max(1, _channelCount / codecContext.pointee.channels) * 2
            let buffer_size = av_samples_get_buffer_size(nil, _channelCount, Int32(temp.sampleCount) * ratio, AV_SAMPLE_FMT_S16, 1)
            if _audio_swr_buffer == nil || _audio_swr_buffer_size < buffer_size {
                _audio_swr_buffer_size = Int(buffer_size)
                _audio_swr_buffer = realloc(_audio_swr_buffer, _audio_swr_buffer_size)
            }
            
            let tempdata = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>.allocate(capacity: 4)
            tempdata.initialize(to: nil)

            let data = UnsafeMutableBufferPointer(start: tempdata, count: 4)
            let test = _audio_swr_buffer?.assumingMemoryBound(to: UInt8.self)
            data.assign(repeating: test)
            
            let dataPointer = withUnsafeMutablePointer(to: &temp.cFramePtr.pointee.data){$0}
                .withMemoryRebound(to: Optional<UnsafePointer<UInt8>>.self, capacity: MemoryLayout<UnsafePointer<UInt8>>.stride * 8) {$0}
            numberOfFrames = swr_convert(c,
                                         data.baseAddress,
                                         Int32(temp.sampleCount) * ratio,
                                         dataPointer,
                                         Int32(temp.sampleCount))
            audioDataBuffer = _audio_swr_buffer
            
        } else {
            print("sss")
        }
        let position = TimeInterval(av_frame_get_best_effort_timestamp(temp.cFramePtr)) * TimeInterval(context!.audioTimebase)
        let duration = TimeInterval(av_frame_get_pkt_duration(temp.cFramePtr)) * TimeInterval(context!.audioTimebase)
        let audioFrame = AudioFrame(position: position, duration: duration)
        
        let numberOfElements = numberOfFrames * _channelCount
        let length = Int(numberOfElements) * MemoryLayout<Float>.size
        audioFrame.setting(samplesLength: length)
        
        var scale = 1.0 / Float(Int16.max)
        let sample = audioFrame.samples!
        vDSP_vflt16(audioDataBuffer!.assumingMemoryBound(to: Int16.self),
                    1,
                    sample.assumingMemoryBound(to: Float.self),
                    1,
                    vDSP_Length(numberOfElements))
        vDSP_vsmul(sample.assumingMemoryBound(to: Float.self),
                   1,
                   &scale,
                   sample.assumingMemoryBound(to: Float.self),
                   1,
                   vDSP_Length(numberOfElements))
        return audioFrame
    }

}
