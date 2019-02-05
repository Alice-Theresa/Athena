//
//  VideoDecoder.swift
//  Athena
//
//  Created by Theresa on 2019/2/4.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation
import VideoToolbox

protocol VideoDecoder {
    var context: SCFormatContext? { get }
    
    func decode(packet: AVPacket) -> NSArray
}

private func callback(decompressionOutputRefCon: UnsafeMutableRawPointer,
                      sourceFrameRefCon: UnsafeMutableRawPointer,
                      status: OSStatus,
                      infoFlags: VTDecodeInfoFlags,
                      imageBuffer: CVImageBuffer?,
                      presentationTimeStamp: CMTime,
                      presentationDuration: CMTime) {
    
}

class VTDecoder: VideoDecoder {
    
    weak var context: SCFormatContext?
    
    var session: VTDecompressionSession?
    var formatDescription: CMVideoFormatDescription?
    
    deinit {
        if let session = session {
            VTDecompressionSessionWaitForAsynchronousFrames(session)
            VTDecompressionSessionInvalidate(session)
        }
    }
    
    init(formatContext: SCFormatContext) {
        context = formatContext
    }
    
    func tryInitDecoder(context: SCFormatContext) -> Bool {
        if let _ = session {
            return true
        }
        return false
    }
    
    func decode(packet: AVPacket) -> NSArray {
        fatalError()
    }
    
    static func CFDictionarySetObject(dict: CFMutableDictionary, key: UnsafeRawPointer, value: UnsafeRawPointer) {
        CFDictionarySetValue(dict, key, value)
    }
}

@objc class FFDecoder: NSObject, VideoDecoder {
    weak var context: SCFormatContext?
    var temp_frame: UnsafeMutablePointer<AVFrame>
    
    @objc init(formatContext: SCFormatContext) {
        context = formatContext
        temp_frame = av_frame_alloc()
    }
    
    @objc func decode(packet: AVPacket) -> NSArray {
        var packet = packet
        let defaultArray = NSArray()
        let array = NSMutableArray()
        guard let _ = packet.data, let context = context else { return defaultArray }
        var result = avcodec_send_packet(context.videoCodecContext, &packet)
        if result < 0 {
            return defaultArray
        }
        while result >= 0 {
            result = avcodec_receive_frame(context.videoCodecContext, temp_frame)
            if result < 0 {
                fatalError() //todo
            } else {
                let frame = videoFrameFromTempFrame(packetSize: Int(packet.size))
                array.add(frame)
            }
        }
        av_packet_unref(&packet)
        return array.copy() as! NSArray
    }
    
    func videoFrameFromTempFrame(packetSize: Int) -> I420VideoFrame?  {
        guard let _ = temp_frame.pointee.data.0,
            let _ = temp_frame.pointee.data.1,
            let _ = temp_frame.pointee.data.2,
            let context = context else { return nil }
        let position = Double(av_frame_get_best_effort_timestamp(temp_frame)) * context.videoTimebase + Double(temp_frame.pointee.repeat_pict) * context.videoTimebase * 0.5
        let duration = Double(av_frame_get_pkt_duration(temp_frame)) * context.videoTimebase
        let videoFrame = I420VideoFrame(position: position,
                                        duration: duration,
                                        width: Int(context.videoCodecContext.pointee.width),
                                        height: Int(context.videoCodecContext.pointee.height),
                                        frame: temp_frame)
        return videoFrame
    }

}
