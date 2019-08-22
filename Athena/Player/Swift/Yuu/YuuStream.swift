//
//  YuuStream.swift
//  Athena
//
//  Created by Skylar on 2019/8/21.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

@objc public final class YuuStream : NSObject {
    let cStreamPtr: UnsafeMutablePointer<AVStream>
    var cStream: AVStream { return cStreamPtr.pointee }
    
    @objc init(cStreamPtr: UnsafeMutablePointer<AVStream>) {
        self.cStreamPtr = cStreamPtr
    }
    
    public var index: Int {
        return Int(cStream.index)
    }
    
    public var id: Int32 {
        get { return cStream.id }
        set { cStreamPtr.pointee.id = newValue }
    }
    
    @objc public var timebase: AVRational {
        get { return cStream.time_base }
        set { cStreamPtr.pointee.time_base = newValue }
    }
    
    public var startTime: Int64 {
        return cStream.start_time
    }
    
    @objc public var duration: Int64 {
        return cStream.duration
    }
    
    public var frameCount: Int {
        return Int(cStream.nb_frames)
    }
    
    public var discard: AVDiscard {
        get { return cStream.discard }
        set { cStreamPtr.pointee.discard = newValue }
    }
    
    public var sampleAspectRatio: AVRational {
        return cStream.sample_aspect_ratio
    }
    
    @objc public var metadata: [String: String] {
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
    
    public var averageFramerate: AVRational {
        get { return cStream.avg_frame_rate }
        set { cStreamPtr.pointee.avg_frame_rate = newValue }
    }
    
    public var realFramerate: AVRational {
        return cStream.r_frame_rate
    }
    
    @objc public var codecParameters: YuuCodecParameters {
        return YuuCodecParameters(cParametersPtr: cStream.codecpar)
    }
    
    public var mediaType: AVMediaType {
        return codecParameters.mediaType
    }
}
