//
//  AudioDecoder.swift
//  Athena
//
//  Created by Theresa on 2019/2/4.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

@objc class AudioDecoder: NSObject {
    
    let _samplingRate: Int32 = 44100
    let _channelCount: Int32 = 2
    
    var temp_frame: UnsafeMutablePointer<AVFrame>?
    var audio_swr_context: OpaquePointer?
    
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
    }

}
