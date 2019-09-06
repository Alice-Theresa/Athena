//
//  YuuPacket.swift
//  Athena
//
//  Created by Skylar on 2019/8/19.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

class YuuPacket {
    
    let cPacketPtr: UnsafeMutablePointer<AVPacket>
    var cPacket: AVPacket { return cPacketPtr.pointee }
    
    deinit {
        var ptr: UnsafeMutablePointer<AVPacket>? = cPacketPtr
        av_packet_free(&ptr)
    }
    
    init() {
        guard let packetPtr = av_packet_alloc() else {
            fatalError()
        }
        self.cPacketPtr = packetPtr
    }
    
    init(cPacketPtr: UnsafeMutablePointer<AVPacket>) {
        self.cPacketPtr = cPacketPtr
    }
    
    var pts: Int64 {
        get { return cPacket.pts }
        set { cPacketPtr.pointee.pts = newValue }
    }
 
    var dts: Int64 {
        get { return cPacket.dts }
        set { cPacketPtr.pointee.dts = newValue }
    }
    
    var data: UnsafeMutablePointer<UInt8>? {
        get { return cPacket.data }
        set { cPacketPtr.pointee.data = newValue }
    }
    
    var size: Int {
        get { return Int(cPacket.size) }
        set { cPacketPtr.pointee.size = Int32(newValue) }
    }
    
    var streamIndex: Int {
        get { return Int(cPacket.stream_index) }
        set { cPacketPtr.pointee.stream_index = Int32(newValue) }
    }
    
    var flags: Flag {
        get { return Flag(rawValue: cPacket.flags) }
        set { cPacketPtr.pointee.flags = newValue.rawValue }
    }
    
    var duration: Int64 {
        get { return cPacket.duration }
        set { cPacketPtr.pointee.duration = newValue }
    }
    
    var position: Int64 {
        get { return cPacket.pos }
        set { cPacketPtr.pointee.pos = newValue }
    }
    
    func unref() {
        av_packet_unref(cPacketPtr)
    }
}

extension YuuPacket {
    
    struct Flag: OptionSet {
        static let key = Flag(rawValue: AV_PKT_FLAG_KEY)
        static let corrupt = Flag(rawValue: AV_PKT_FLAG_CORRUPT)
        static let discard = Flag(rawValue: AV_PKT_FLAG_DISCARD)
        static let trusted = Flag(rawValue: AV_PKT_FLAG_TRUSTED)
        
        let rawValue: Int32
    }
}
