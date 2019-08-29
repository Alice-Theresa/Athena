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
    var context: FormatContext? { get }
    
    func decode(packet: YuuPacket) -> Array<Frame>
}

class VTDecoder: VideoDecoder {
    
    weak var context: FormatContext?
    
    var session: VTDecompressionSession?
    var formatDescription: CMVideoFormatDescription?
    
    deinit {
        if let session = session {
            VTDecompressionSessionWaitForAsynchronousFrames(session)
            VTDecompressionSessionInvalidate(session)
        }
    }
    
    init(formatContext: FormatContext) {
        context = formatContext
        tryInitDecoder(context: formatContext)
    }
    
    @discardableResult
    func tryInitDecoder(context: FormatContext) -> Bool {
        if let _ = session {
            return true
        }
        let codecContext = context.videoCodecContext
        let extradata = codecContext!.extradata
        let dataSize = codecContext!.extradataSize
        
        guard let data = extradata else { return false }
        if dataSize < 7 || data[0] != 1 {
            return false
        } else {
            formatDescription = createFormatDescription(codec_type: kCMVideoCodecType_H264,
                                                        width: Int32(codecContext!.width),
                                                        height: Int32(codecContext!.height),
                                                        extradata: data,
                                                        extradata_size: Int32(dataSize))
            guard let desc = formatDescription else { return false }
            let destinationPixelBufferAttributes = NSMutableDictionary()
            destinationPixelBufferAttributes.setValue(NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange), forKey: kCVPixelBufferPixelFormatTypeKey as String)
            var callBackRecord = VTDecompressionOutputCallbackRecord()
            callBackRecord.decompressionOutputCallback = YuuDidDecompress
            callBackRecord.decompressionOutputRefCon = Unmanaged.passUnretained(self).toOpaque()
            let status = VTDecompressionSessionCreate(allocator: kCFAllocatorDefault,
                                                      formatDescription: desc,
                                                      decoderSpecification: NSMutableDictionary(),
                                                      imageBufferAttributes: destinationPixelBufferAttributes,
                                                      outputCallback: &callBackRecord,
                                                      decompressionSessionOut: &session)
            return status == noErr
        }
    }
    
    func decode(packet: YuuPacket) -> Array<Frame> {
        var outputPixelBuffer: CVPixelBuffer?
        var blockBuffer: CMBlockBuffer?
        var status = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault,
                                                        memoryBlock: packet.data,
                                                        blockLength: Int(packet.size),
                                                        blockAllocator: kCFAllocatorNull,
                                                        customBlockSource: nil,
                                                        offsetToData: 0,
                                                        dataLength: Int(packet.size),
                                                        flags: 0,
                                                        blockBufferOut: &blockBuffer)
        if status == kCMBlockBufferNoErr {
            var sampleBuffer: CMSampleBuffer?
            status = CMSampleBufferCreate(allocator: kCFAllocatorDefault,
                                          dataBuffer: blockBuffer,
                                          dataReady: true,
                                          makeDataReadyCallback: nil,
                                          refcon: nil,
                                          formatDescription: formatDescription,
                                          sampleCount: 1,
                                          sampleTimingEntryCount: 0,
                                          sampleTimingArray: nil,
                                          sampleSizeEntryCount: 0,
                                          sampleSizeArray: nil,
                                          sampleBufferOut: &sampleBuffer)
            if (status == kCMBlockBufferNoErr) {
                if let sampleBuffer = sampleBuffer, let session = session {
                    var flagsOut: VTDecodeInfoFlags = []
                    let decodeStatus = VTDecompressionSessionDecodeFrame(session, sampleBuffer: sampleBuffer, flags: [], frameRefcon: &outputPixelBuffer, infoFlagsOut: &flagsOut)
                    if(decodeStatus == kVTInvalidSessionErr) {
                        
                    } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                        
                    } else if(decodeStatus != noErr) {
                        
                    }
                    if let outputPixelBuffer = outputPixelBuffer, let context = context {
                        let videoFrame = NV12VideoFrame(position: Double(packet.pts) * context.videoTimebase,
                                                        duration: Double(packet.duration) * context.videoTimebase,
                                                        pixelBuffer: outputPixelBuffer)
                        packet.unref()
                        return [videoFrame]
                    }
                }
            }
        }
        packet.unref()
        return []
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

class FFDecoder: VideoDecoder {
    weak var context: FormatContext?
    var tempFrame: YuuFrame
    
    init(formatContext: FormatContext) {
        context = formatContext
        tempFrame = YuuFrame()
    }
    
    func decode(packet: YuuPacket) -> Array<Frame> {
        let defaultArray: [Frame] = []
        var array: [Frame] = []
        guard let _ = packet.data, let context = context, let vcc = context.videoCodecContext else { return defaultArray }
        do {
            try vcc.sendPacket(packet)
        } catch {
            return defaultArray
        }
        while true {
            do {
                try vcc.receiveFrame(tempFrame)
                if let frame = videoFrameFromTempFrame(packetSize: Int(packet.size)) {
                    array.append(frame)
                }
            } catch {
                break
            }
        }
        packet.unref()
        return array
    }
    
    func videoFrameFromTempFrame(packetSize: Int) -> I420VideoFrame?  {
        guard let _ = tempFrame.data[0],
            let _ = tempFrame.data[1],
            let _ = tempFrame.data[2],
            let context = context,
            let vcc = context.videoCodecContext else { return nil }
        let position = Double(av_frame_get_best_effort_timestamp(tempFrame.cFramePtr)) * context.videoTimebase + Double(tempFrame.repeatPicture) * context.videoTimebase * 0.5
        let duration = Double(av_frame_get_pkt_duration(tempFrame.cFramePtr)) * context.videoTimebase
        let videoFrame = I420VideoFrame(position: position,
                                        duration: duration,
                                        width: vcc.width,
                                        height: vcc.height,
                                        frame: tempFrame)
        return videoFrame
    }

}
