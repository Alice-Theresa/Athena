//
//  YuuStream.swift
//  Athena
//
//  Created by Skylar on 2019/8/21.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

class YuuStream : NSObject {
    let cStreamPtr: UnsafeMutablePointer<AVStream>
    var cStream: AVStream { return cStreamPtr.pointee }
    
    init(cStreamPtr: UnsafeMutablePointer<AVStream>) {
        self.cStreamPtr = cStreamPtr
    }
    
    var index: Int {
        return Int(cStream.index)
    }
    
    var id: Int32 {
        get { return cStream.id }
        set { cStreamPtr.pointee.id = newValue }
    }
    
    var timebase: AVRational {
        get { return cStream.time_base }
        set { cStreamPtr.pointee.time_base = newValue }
    }
    
    var startTime: Int64 {
        return cStream.start_time
    }
    
    var duration: Int64 {
        return cStream.duration
    }
    
    var frameCount: Int {
        return Int(cStream.nb_frames)
    }
    
    var discard: AVDiscard {
        get { return cStream.discard }
        set { cStreamPtr.pointee.discard = newValue }
    }
    
    var sampleAspectRatio: AVRational {
        return cStream.sample_aspect_ratio
    }
    
    var metadata: [String: String] {
        get {
            var dict = [String: String]()
            var prev: UnsafeMutablePointer<AVDictionaryEntry>?
            while let tag = av_dict_get(cStream.metadata, "", prev, AV_DICT_IGNORE_SUFFIX) {
                dict[String(cString: tag.pointee.key)] = String(cString: tag.pointee.value)
                prev = tag
            }
            return dict
        }
        set { cStreamPtr.pointee.metadata = newValue.toAVDict() }
    }
    
    var averageFramerate: AVRational {
        get { return cStream.avg_frame_rate }
        set { cStreamPtr.pointee.avg_frame_rate = newValue }
    }
    
    var realFramerate: AVRational {
        return cStream.r_frame_rate
    }
    
    var codecParameters: YuuCodecParameters {
        return YuuCodecParameters(cParametersPtr: cStream.codecpar)
    }
    
    public var mediaType: AVMediaType {
        return codecParameters.mediaType
    }
}
