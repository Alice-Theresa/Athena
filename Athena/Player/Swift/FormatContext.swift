//
//  FormatContext.swift
//  Athena
//
//  Created by Skylar on 2019/8/19.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

class FormatContext {
    
    var videoIndex = -1
    var audioIndex = -1
    var subtitleIndex = -1
    
    var videoTimebase: TimeInterval = 0
    var audioTimebase: TimeInterval = 0
    var duration: TimeInterval = 0
    
    var videoTracks: [Track] = []
    var audioTracks: [Track] = []
    var subtitleTracks: [Track] = []
    
    let formatContext: YuuFormatContext
    var videoCodecContext: YuuCodecContext?
    var audioCodecContext: YuuCodecContext?
    
    init() {
        av_register_all()
        avformat_network_init()
        formatContext = YuuFormatContext()
    }
    
    func open(path: String) {
        var p = formatContext.cContextPtr
        if avformat_open_input(&p, (path as NSString).utf8String, nil, nil) != 0 {
            print("Couldn't open input stream.\n")
            return
        }
        if avformat_find_stream_info(p, nil) < 0 {
            print("Couldn't find stream information.\n")
            return
        }
        for (index, stream) in formatContext.streams.enumerated() {
            switch stream.codecParameters.mediaType {
            case AVMEDIA_TYPE_VIDEO:
                videoTracks.append(Track(type: .Video, index: index, metadata: stream.metadata))
            case AVMEDIA_TYPE_AUDIO:
                audioTracks.append(Track(type: .Audio, index: index, metadata: stream.metadata))
            case AVMEDIA_TYPE_SUBTITLE:
                subtitleTracks.append(Track(type: .Subtitle, index: index, metadata: stream.metadata))
            default:
                break
            }
        }
        videoIndex = videoTracks.first?.index ?? -1
        audioIndex = audioTracks.first?.index ?? -1
        subtitleIndex = subtitleTracks.first?.index ?? -1
        let videoStream = formatContext.streams[videoIndex]
        let audioStream = formatContext.streams[audioIndex]
        let videoCodec = YuuCodec.findDecoderById(AVCodecID(rawValue: videoStream.codecParameters.codecId.rawValue))
        let audioCodec = YuuCodec.findDecoderById(AVCodecID(rawValue: audioStream.codecParameters.codecId.rawValue))
        videoCodecContext = YuuCodecContext(codec: videoCodec)
        audioCodecContext = YuuCodecContext(codec: audioCodec)
        videoCodecContext?.setParameters(videoStream.codecParameters)
        audioCodecContext?.setParameters(audioStream.codecParameters)
        guard let vc = videoCodec, let ac = audioCodec else {
            print("Couldn't find Codec.\n")
            return
        }
        do {
            try videoCodecContext?.openCodec()
            try audioCodecContext?.openCodec()
        } catch {
            print("Couldn't open codec.\n")
        }
        settingTimeBase()
        settingDuration()
    }
    
    func read(packet: YuuPacket) -> Int {
        return Int(av_read_frame(formatContext.cContextPtr, packet.cPacketPtr))
    }
    
    func seeking(time: TimeInterval) {
        
    }
    
    func closeFile() {
        var p = formatContext.cContextPtr
        avcodec_close(videoCodecContext?.cContextPtr)
        avcodec_close(audioCodecContext?.cContextPtr)
        avformat_close_input(&p)
    }
    
    private func settingTimeBase() {
        let stream = formatContext.streams[videoIndex]
        if stream.timebase.den > 0 && stream.timebase.num > 0 {
            videoTimebase = av_q2d(stream.timebase)
        }
        let audioStream = formatContext.streams[audioIndex]
        if audioStream.timebase.den > 0 && audioStream.timebase.num > 0 {
            audioTimebase = av_q2d(audioStream.timebase)
        }
    }
    
    private func settingDuration() {
        duration = TimeInterval(formatContext.duration) / TimeInterval(AV_TIME_BASE)
    }
}

