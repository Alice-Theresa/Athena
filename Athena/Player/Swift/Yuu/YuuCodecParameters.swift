//
//  YuuCodecParameters.swift
//  Athena
//
//  Created by Skylar on 2019/8/21.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

@objc public final class YuuCodecParameters: NSObject {
    @objc let cParametersPtr: UnsafeMutablePointer<AVCodecParameters>
    @objc var cParameters: AVCodecParameters { return cParametersPtr.pointee }
    
    private var freeWhenDone: Bool = false
    
    init(cParametersPtr: UnsafeMutablePointer<AVCodecParameters>) {
        self.cParametersPtr = cParametersPtr
    }
    
    /// Create a new `AVCodecParameters` and set its fields to default values (unknown/invalid/0).
    public override init() {
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
    
    /// General type of the encoded data.
    @objc public var mediaType: AVMediaType {
        get { return cParameters.codec_type }
        set { cParametersPtr.pointee.codec_type = newValue }
    }
    
    /// Specific type of the encoded data (the codec used).
    public var codecId: AVCodecID {
        get { return cParameters.codec_id }
        set { cParametersPtr.pointee.codec_id = newValue }
    }
    
    /// Additional information about the codec (corresponds to the AVI FOURCC).
    public var codecTag: UInt32 {
        get { return cParameters.codec_tag }
        set { cParametersPtr.pointee.codec_tag = newValue }
    }
    
    /// Extra binary data needed for initializing the decoder, codec-dependent.
    ///
    /// Must be allocated with `AVIO.malloc(size:)` and will be freed by
    /// `avcodec_parameters_free()`. The allocated size of extradata must be at
    /// least `extradataSize + AVConstant.inputBufferPaddingSize`, with the padding
    /// bytes zeroed.
    public var extradata: UnsafeMutablePointer<UInt8>? {
        get { return cParameters.extradata }
        set { cParametersPtr.pointee.extradata = newValue }
    }
    
    /// The size of the extradata content in bytes.
    public var extradataSize: Int {
        get { return Int(cParameters.extradata_size) }
        set { cParametersPtr.pointee.extradata_size = Int32(newValue) }
    }
    
    /// The average bitrate of the encoded data (in bits per second).
    public var bitRate: Int64 {
        get { return cParameters.bit_rate }
        set { cParametersPtr.pointee.bit_rate = newValue }
    }
    
    /// Copy the contents from the supplied codec parameters.
//    public func copy(from codecpar: AVCodecParameters) {
//        abortIfFail(avcodec_parameters_copy(cParametersPtr, codecpar.cParametersPtr))
//    }
//
//    /// Fill the parameters struct based on the values from the supplied codec context.
//    public func copy(from codecCtx: AVCodecContext) {
//        abortIfFail(avcodec_parameters_from_context(cParametersPtr, codecCtx.cContextPtr))
//    }
}

// MARK: - Video
extension YuuCodecParameters {
    
    /// The pixel format of the video frame.
    public var pixelFormat: AVPixelFormat {
        get { return AVPixelFormat(cParameters.format) }
        set { cParametersPtr.pointee.format = newValue.rawValue }
    }
    
    /// The width of the video frame in pixels.
    public var width: Int {
        get { return Int(cParameters.width) }
        set { cParametersPtr.pointee.width = Int32(newValue) }
    }
    
    /// The height of the video frame in pixels.
    public var height: Int {
        get { return Int(cParameters.height) }
        set { cParametersPtr.pointee.height = Int32(newValue) }
    }
    
    /// The aspect ratio (width / height) which a single pixel should have when displayed.
    ///
    /// When the aspect ratio is unknown / undefined, the numerator should be set to 0
    /// (the denominator may have any value).
    public var sampleAspectRatio: AVRational {
        get { return cParameters.sample_aspect_ratio }
        set { cParametersPtr.pointee.sample_aspect_ratio = newValue }
    }
    
    /// Number of delayed frames.
    public var videoDelay: Int {
        get { return Int(cParameters.video_delay) }
        set { cParametersPtr.pointee.video_delay = Int32(newValue) }
    }
}
