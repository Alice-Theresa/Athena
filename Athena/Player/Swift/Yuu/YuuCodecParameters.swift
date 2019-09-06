//
//  YuuCodecParameters.swift
//  Athena
//
//  Created by Skylar on 2019/8/21.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

class YuuCodecParameters {
    let cParametersPtr: UnsafeMutablePointer<AVCodecParameters>
    var cParameters: AVCodecParameters { return cParametersPtr.pointee }
    
    private var freeWhenDone: Bool = false
    
    init(cParametersPtr: UnsafeMutablePointer<AVCodecParameters>) {
        self.cParametersPtr = cParametersPtr
    }
    
    init() {
        guard let ptr = avcodec_parameters_alloc() else {
            fatalError()
        }
        self.cParametersPtr = ptr
        self.freeWhenDone = true
    }
    
    deinit {
        if freeWhenDone {
            var ps: UnsafeMutablePointer<AVCodecParameters>? = cParametersPtr
            avcodec_parameters_free(&ps)
        }
    }
    
    var mediaType: AVMediaType {
        get { return cParameters.codec_type }
        set { cParametersPtr.pointee.codec_type = newValue }
    }
    
    var codecId: AVCodecID {
        get { return cParameters.codec_id }
        set { cParametersPtr.pointee.codec_id = newValue }
    }
    
    var extradata: UnsafeMutablePointer<UInt8>? {
        get { return cParameters.extradata }
        set { cParametersPtr.pointee.extradata = newValue }
    }
    
    var extradataSize: Int {
        get { return Int(cParameters.extradata_size) }
        set { cParametersPtr.pointee.extradata_size = Int32(newValue) }
    }
    
    var bitRate: Int64 {
        get { return cParameters.bit_rate }
        set { cParametersPtr.pointee.bit_rate = newValue }
    }
    
}

extension YuuCodecParameters {
    
    var pixelFormat: AVPixelFormat {
        get { return AVPixelFormat(cParameters.format) }
        set { cParametersPtr.pointee.format = newValue.rawValue }
    }
    
    var width: Int {
        get { return Int(cParameters.width) }
        set { cParametersPtr.pointee.width = Int32(newValue) }
    }
    
    var height: Int {
        get { return Int(cParameters.height) }
        set { cParametersPtr.pointee.height = Int32(newValue) }
    }
    
    var sampleAspectRatio: AVRational {
        get { return cParameters.sample_aspect_ratio }
        set { cParametersPtr.pointee.sample_aspect_ratio = newValue }
    }
    
    var videoDelay: Int {
        get { return Int(cParameters.video_delay) }
        set { cParametersPtr.pointee.video_delay = Int32(newValue) }
    }
}
