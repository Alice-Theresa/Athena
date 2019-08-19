//
//  Frame.swift
//  Athena
//
//  Created by Theresa on 2019/2/3.
//  Copyright © 2019 Theresa. All rights reserved.
//

import MetalKit
import Foundation

@objc public protocol Frame: NSObjectProtocol {
    var position: TimeInterval { get }
    var duration: TimeInterval { get }
}

@objc class MarkerFrame: NSObject, Frame {
    var position: TimeInterval = -.greatestFiniteMagnitude
    var duration: TimeInterval = -.greatestFiniteMagnitude
}

@objc class AudioFrame: NSObject, Frame {
    var position: TimeInterval
    var duration: TimeInterval
    
    @objc var samples: UnsafeMutableRawPointer?
    @objc var length: Int = 0
    @objc var outputOffset: Int = 0
    var bufferSize: Int = 0
    
    deinit {
        free(samples)
    }
    
    @objc init(position: TimeInterval, duration: TimeInterval) {
        self.position = position
        self.duration = duration
    }
    
    @objc func setting(samplesLength: Int) {
        if bufferSize < samplesLength {
            if (bufferSize > 0 && samples != nil) {
                free(samples)
            }
            bufferSize = samplesLength
            samples = malloc(bufferSize)
        }
        length = samplesLength
        outputOffset = 0
    }
}

@objc class NV12VideoFrame: NSObject, Frame, RenderDataNV12 {
    let width: Int
    let height: Int
    let pixelBuffer: CVPixelBuffer
    
    let position: TimeInterval
    let duration: TimeInterval
    
    @objc init(position: TimeInterval, duration: TimeInterval, pixelBuffer: CVPixelBuffer) {
        self.position = position
        self.duration = duration
        self.pixelBuffer = pixelBuffer
        self.width = CVPixelBufferGetWidth(pixelBuffer)
        self.height = CVPixelBufferGetHeight(pixelBuffer)
    }
}

@objc class I420VideoFrame: NSObject, Frame, RenderDataI420 {
    var luma_channel_pixels: UnsafeMutablePointer<UInt8>
    var chromaB_channel_pixels: UnsafeMutablePointer<UInt8>
    var chromaR_channel_pixels: UnsafeMutablePointer<UInt8>
    
    let width: Int
    let height: Int
    
    let position: TimeInterval
    let duration: TimeInterval
    
    deinit {
        luma_channel_pixels.deallocate()
        chromaB_channel_pixels.deallocate()
        chromaR_channel_pixels.deallocate()
    }
    
    @objc init(position: TimeInterval, duration: TimeInterval, width: Int, height: Int, frame: YuuFrame) {
        self.position = position
        self.duration = duration
        self.width = width
        self.height = height
        
        let linesize_y = Int(frame.linesize[0])
        let linesize_u = Int(frame.linesize[1])
        let linesize_v = Int(frame.linesize[2])
        
        let needsize_y = I420VideoFrame.checkSize(width: width, height: height, lineSize: linesize_y)
        let needsize_u = I420VideoFrame.checkSize(width: width/2, height: height/2, lineSize: linesize_u)
        let needsize_v = I420VideoFrame.checkSize(width: width/2, height: height/2, lineSize: linesize_v)
        
        luma_channel_pixels = UnsafeMutablePointer<UInt8>.allocate(capacity: needsize_y)
        chromaB_channel_pixels = UnsafeMutablePointer<UInt8>.allocate(capacity: needsize_u)
        chromaR_channel_pixels = UnsafeMutablePointer<UInt8>.allocate(capacity: needsize_v)
        
        I420VideoFrame.copyData(width: width, height: height, src: frame.data[0]!, des: luma_channel_pixels, dataSize: needsize_y)
        I420VideoFrame.copyData(width: width / 2, height: height / 2, src: frame.data[1]!, des: chromaB_channel_pixels, dataSize: needsize_u)
        I420VideoFrame.copyData(width: width / 2, height: height / 2, src: frame.data[2]!, des: chromaR_channel_pixels, dataSize: needsize_v)
    }
    
    static func checkSize(width: Int, height: Int, lineSize: Int) -> Int {
        return max(width, lineSize) * height
    }
    
    static func copyData(width: Int, height: Int, src: UnsafeMutablePointer<UInt8>, des: UnsafeMutablePointer<UInt8>, dataSize: Int) {
        var temp = des
        var src = src
        memset(des, 0, dataSize)
        for _ in 0..<height {
            memcpy(temp, src, width)
            temp += width
            src += width;
        }
    }
}
