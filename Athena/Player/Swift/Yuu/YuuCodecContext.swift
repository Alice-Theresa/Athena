//
//  YuuCodecContext.swift
//  Athena
//
//  Created by Skylar on 2019/8/23.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

/// Allows to "box" another value.
final class Box<T> {
    let value: T
    
    init(_ value: T) {
        self.value = value
    }
}

extension UnsafePointer {
    
    var mutable: UnsafeMutablePointer<Pointee> {
        return UnsafeMutablePointer(mutating: self)
    }
}

public typealias AVGetFormatHandler = (AVCodecContext, [AVPixelFormat]) -> AVPixelFormat

typealias CodecContextBoxValue = (
    opaque: UnsafeMutableRawPointer?,
    getFormat: AVGetFormatHandler?
)
typealias CodecContextBox = Box<CodecContextBoxValue>

class YuuCodecContext {
    let cContextPtr: UnsafeMutablePointer<AVCodecContext>
    var cContext: AVCodecContext { return cContextPtr.pointee }
    
    fileprivate var opaqueBox: CodecContextBox? {
        didSet {
            if let box = opaqueBox {
                cContextPtr.pointee.opaque = Unmanaged.passUnretained(box).toOpaque()
            } else {
                cContextPtr.pointee.opaque = nil
            }
        }
    }
    private var freeWhenDone: Bool = false
    
    init(cContextPtr: UnsafeMutablePointer<AVCodecContext>) {
        self.cContextPtr = cContextPtr
    }
    
    /// Creates an `AVCodecContext` and set its fields to default values.
    ///
    /// - Parameter codec: codec
    public init(codec: YuuCodec? = nil) {
        guard let ctxPtr = avcodec_alloc_context3(codec?.cCodecPtr) else {
            fatalError()
        }
        self.cContextPtr = ctxPtr
        self.freeWhenDone = true
    }
    
    deinit {
        if freeWhenDone {
            var ps: UnsafeMutablePointer<AVCodecContext>? = cContextPtr
            avcodec_free_context(&ps)
        }
    }
    
    /// The codec's media type.
    public var mediaType: AVMediaType {
        return cContext.codec_type
    }
    
    public var codec: YuuCodec? {
        get {
            if let ptr = cContext.codec {
                return YuuCodec(cCodecPtr: ptr.mutable)
            }
            return nil
        }
        set { cContextPtr.pointee.codec = UnsafePointer(newValue?.cCodecPtr) }
    }
    
    /// The codec's id.
    public var codecId: AVCodecID {
        get { return cContext.codec_id }
        set { cContextPtr.pointee.codec_id = newValue }
    }
    
    /// Private data of the user, can be used to carry app specific stuff.
    ///
    /// - encoding: Set by user.
    /// - decoding: Set by user.
    public var opaque: UnsafeMutableRawPointer? {
        get { return opaqueBox?.value.opaque }
        set { opaqueBox = CodecContextBox((opaque: newValue, getFormat: opaqueBox?.value.getFormat)) }
    }
    
    var bitRate: Int64 {
        get { return cContext.bit_rate }
        set { cContextPtr.pointee.bit_rate = newValue }
    }
    
    /// Number of bits the bitstream is allowed to diverge from the reference.
    /// The reference can be CBR (for CBR pass1) or VBR (for pass2).
    ///
    /// - encoding: Set by user, unused for constant quantizer encoding.
    /// - decoding: Unused.
    public var bitRateTolerance: Int {
        get { return Int(cContext.bit_rate_tolerance) }
        set { cContextPtr.pointee.bit_rate_tolerance = Int32(newValue) }
    }
    
    
    /// Some codecs need / can use extradata like Huffman tables.
    ///
    /// - MJPEG: Huffman tables
    /// - rv10: additional flags
    /// - MPEG-4: global headers (they can be in the bitstream or here)
    ///
    /// The allocated memory should be `AVConstant.inputBufferPaddingSize` bytes larger
    /// than `extradataSize` to avoid problems if it is read with the bitstream reader.
    /// The bytewise contents of extradata must not depend on the architecture or CPU endianness.
    /// Must be allocated with the `AVIO.malloc(size:)` family of functions.
    ///
    /// - encoding: Set/allocated/freed by libavcodec.
    /// - decoding: Set/allocated/freed by user.
    public var extradata: UnsafeMutablePointer<UInt8>? {
        get { return cContext.extradata }
        set { cContextPtr.pointee.extradata = newValue }
    }
    
    /// The size of the extradata content in bytes.
    public var extradataSize: Int {
        get { return Int(cContext.extradata_size) }
        set { cContextPtr.pointee.extradata_size = Int32(newValue) }
    }
    
    /// This is the fundamental unit of time (in seconds) in terms of which frame timestamps
    /// are represented. For fixed-fps content, timebase should be 1/framerate and timestamp
    /// increments should be identically 1.
    /// This often, but not always is the inverse of the frame rate or field rate for video.
    /// 1/timebase is not the average frame rate if the frame rate is not constant.
    ///
    /// Like containers, elementary streams also can store timestamps, 1/timebase
    /// is the unit in which these timestamps are specified.
    /// As example of such codec timebase see ISO/IEC 14496-2:2001(E)
    /// vop_time_increment_resolution and fixed_vop_rate
    /// (fixed_vop_rate == 0 implies that it is different from the framerate)
    ///
    /// - encoding: Must be set by user.
    /// - decoding: The use of this field for decoding is deprecated. Use framerate instead.
    public var timebase: AVRational {
        get { return cContext.time_base }
        set { cContextPtr.pointee.time_base = newValue }
    }
    
    func sendPacket(_ packet: YuuPacket?) throws {
        try throwIfFail(avcodec_send_packet(cContextPtr, packet?.cPacketPtr))
    }
    
    func receiveFrame(_ frame: YuuFrame) throws {
        try throwIfFail(avcodec_receive_frame(cContextPtr, frame.cFramePtr))
    }
    
    var isOpen: Bool {
        return avcodec_is_open(cContextPtr) > 0
    }
    
    func setParameters(_ params: YuuCodecParameters) {
        avcodec_parameters_to_context(cContextPtr, params.cParametersPtr)
    }
    
    /// Initialize the `AVCodecContext`.
    ///
    /// - Parameters:
    ///   - codec: The codec to open this context for. If a non-NULL codec has been previously
    ///     passed to `init(codec:)` or for this context, then this parameter _MUST_ be either `nil`
    ///     or equal to the previously passed codec.
    ///   - options: A dictionary filled with `AVCodecContext` and codec-private options.
    /// - Throws: AVError
    public func openCodec(_ codec: YuuCodec? = nil, options: [String: String]? = nil) throws {
        var pm: OpaquePointer? = options?.toAVDict()
        defer { av_dict_free(&pm) }

        try throwIfFail(avcodec_open2(cContextPtr, codec?.cCodecPtr ?? self.codec?.cCodecPtr, &pm))

        dumpUnrecognizedOptions(pm)
    }

}

extension YuuCodecContext {
    
    var width: Int {
        get { return Int(cContext.width) }
        set { cContextPtr.pointee.width = Int32(newValue) }
    }
    
    var height: Int {
        get { return Int(cContext.height) }
        set { cContextPtr.pointee.height = Int32(newValue) }
    }
}
