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
    
    var videoTimebase = 0
    var audioTimebase = 0
    var duration = 0
    
    let formatContext: YuuFormatContext
    
    var videoTracks: [Track] = []
    var audioTracks: [Track] = []
    var subtitleTracks: [Track] = []
    
    
    init() {
        av_register_all()
        avformat_network_init()
        formatContext = YuuFormatContext()
    }
    
    func open(path: NSString) {
        var p = formatContext.cContextPtr
        if avformat_open_input(&p, path.utf8String, nil, nil) != 0 {
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
//        videoIndex = videoTracks.first?.index
//        audioIndex = audioTracks.first?.index
//        subtitleIndex = subtitleTracks.first?.index
//        let videoStream = formatContext.cContext.streams[videoIndex]
    }
        
}
