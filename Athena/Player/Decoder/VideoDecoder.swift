//
//  VideoDecoder.swift
//  Athena
//
//  Created by Theresa on 2019/2/4.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation
import VideoToolbox

@objc protocol VideoDecoder {
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
    var outputPixelBuffer = sourceFrameRefCon.assumingMemoryBound(to: CVPixelBuffer.self);
    if let imageBuffer = imageBuffer {
        outputPixelBuffer = UnsafeMutablePointer(Unmanaged.passRetained(imageBuffer).toOpaque())
    }
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
        let codecContext = context.videoCodecContext
        let extradata = codecContext.pointee.extradata
        let dataSize = codecContext.pointee.extradata_size
        
        guard let data = extradata else { return false }
        if dataSize < 7 || data[0] != 1 {
            return false
        } else {
            formatDescription = createFormatDescription(codec_type: kCMVideoCodecType_H264,
                                                        width: codecContext.pointee.width,
                                                        height: codecContext.pointee.height,
                                                        extradata: data,
                                                        extradata_size: dataSize)
            guard let desc = formatDescription else { return false }
            let destinationPixelBufferAttributes = NSMutableDictionary()
            destinationPixelBufferAttributes.setValue(NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange), forKey: kCVPixelBufferPixelFormatTypeKey as String)
            var callBackRecord = VTDecompressionOutputCallbackRecord()
            callBackRecord.decompressionOutputCallback = callback as? VTDecompressionOutputCallback
            callBackRecord.decompressionOutputRefCon = Unmanaged.passUnretained(self).toOpaque()
            let status = VTDecompressionSessionCreate(allocator: kCFAllocatorDefault,
                                                      formatDescription: desc,
                                                      decoderSpecification: NSMutableDictionary(),
                                                      imageBufferAttributes: destinationPixelBufferAttributes,
                                                      outputCallback: &callBackRecord,
                                                      decompressionSessionOut: &session)
            if status != noErr {
                return false
            } else {
                return true
            }
        }
    }
    
    func decode(packet: AVPacket) -> NSArray {
        fatalError()
    }
    
    func createFormatDescription(codec_type: CMVideoCodecType, width: Int32, height: Int32, extradata: UnsafePointer<UInt8>, extradata_size: Int32) -> CMFormatDescription? {
        let par = NSMutableDictionary()
        par.setObject(0 as NSNumber, forKey: "HorizontalSpacing" as NSString)
        par.setObject(0 as NSNumber, forKey: "VerticalSpacing" as NSString)
        
        let atoms = NSMutableDictionary()
        atoms.setObject(NSData(bytes: extradata, length: Int(extradata_size)), forKey: "avcC" as NSString)
        
        let extensions = NSMutableDictionary()
        extensions.setObject(par, forKey: "CVPixelAspectRatio" as NSString)
        extensions.setObject(atoms, forKey: "SampleDescriptionExtensionAtoms" as NSString)
        extensions.setObject("avcC" as NSString, forKey: "FormatName" as NSString)
        extensions.setObject("left" as NSString, forKey: "CVImageBufferChromaLocationBottomField" as NSString)
        extensions.setObject("left" as NSString, forKey: "CVImageBufferChromaLocationTopField" as NSString)
        extensions.setObject(0 as NSNumber, forKey: "FullRangeVideo" as NSString)
        
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreate(allocator: nil, codecType: CMVideoCodecType(codec_type), width: width, height: height, extensions: extensions, formatDescriptionOut: &formatDescription)
        return formatDescription
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
                break
            } else {
                if let frame = videoFrameFromTempFrame(packetSize: Int(packet.size)) {
                    array.add(frame)
                }
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



