//
//  YuuCodecContext.swift
//  Athena
//
//  Created by Skylar on 2019/8/23.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

extension UnsafePointer {
    
    var mutable: UnsafeMutablePointer<Pointee> {
        return UnsafeMutablePointer(mutating: self)
    }
}

public typealias AVGetFormatHandler = (AVCodecContext, [AVPixelFormat]) -> AVPixelFormat

class YuuCodecContext {
    let cContextPtr: UnsafeMutablePointer<AVCodecContext>
    var cContext: AVCodecContext { return cContextPtr.pointee }
    
    private var freeWhenDone: Bool = false
    
    init(cContextPtr: UnsafeMutablePointer<AVCodecContext>) {
        self.cContextPtr = cContextPtr
    }
    
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
    
    public var codecId: AVCodecID {
        get { return cContext.codec_id }
        set { cContextPtr.pointee.codec_id = newValue }
    }
    
    var bitRate: Int64 {
        get { return cContext.bit_rate }
        set { cContextPtr.pointee.bit_rate = newValue }
    }
    
    var extradata: UnsafeMutablePointer<UInt8>? {
        get { return cContext.extradata }
        set { cContextPtr.pointee.extradata = newValue }
    }
    
    var extradataSize: Int {
        get { return Int(cContext.extradata_size) }
        set { cContextPtr.pointee.extradata_size = Int32(newValue) }
    }
    
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
