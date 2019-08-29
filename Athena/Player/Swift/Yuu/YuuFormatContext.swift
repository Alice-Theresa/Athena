//
//  SCFormatContext.swift
//  Athena
//
//  Created by Skylar on 2019/8/19.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

class YuuFormatContext {
    
    var cContextPtr: UnsafeMutablePointer<AVFormatContext>!
    var cContext: AVFormatContext { return cContextPtr.pointee }
    
    init(cContextPtr: UnsafeMutablePointer<AVFormatContext>) {
        self.cContextPtr = cContextPtr
    }
    
    init() {
        guard let ctxPtr = avformat_alloc_context() else {
            fatalError()
        }
        self.cContextPtr = ctxPtr
    }
    
    var streams: [YuuStream] {
        var list = [YuuStream]()
        for i in 0..<streamCount {
            let stream = cContext.streams.advanced(by: i).pointee!
            list.append(YuuStream(cStreamPtr: stream))
        }
        return list
    }
    
    var streamCount: Int {
        return Int(cContext.nb_streams)
    }
    
    func findStreamInfo(options: [[String: String]]? = nil) throws {
        if let options = options, !options.isEmpty {
            var pms = [OpaquePointer?](repeating: nil, count: streamCount)
            for (i, opt) in options.enumerated() where i < streamCount {
                pms[i] = opt.toAVDict()
            }
            try throwIfFail(avformat_find_stream_info(cContextPtr, &pms))
            pms.forEach { pm in
                var pm = pm
//                dumpUnrecognizedOptions(pm)
                av_dict_free(&pm)
            }
        } else {
            try throwIfFail(avformat_find_stream_info(cContextPtr, nil))
        }
    }
    var duration: Int64 {
        return cContext.duration
    }
    
    var metadata: [String: String] {
        get {
            var dict = [String: String]()
            var prev: UnsafeMutablePointer<AVDictionaryEntry>?
            while let tag = av_dict_get(cContext.metadata, "", prev, AV_DICT_IGNORE_SUFFIX) {
                dict[String(cString: tag.pointee.key)] = String(cString: tag.pointee.value)
                prev = tag
            }
            return dict
        }
        set { cContextPtr.pointee.metadata = newValue.toAVDict() }
    }

    func seekFrame(to timestamp: Int64, streamIndex: Int) throws {
        try throwIfFail(av_seek_frame(cContextPtr, Int32(streamIndex), timestamp, AVSEEK_FLAG_BACKWARD))
    }
    
}
