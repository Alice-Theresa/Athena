//
//  Frame.swift
//  Athena
//
//  Created by Theresa on 2019/2/3.
//  Copyright © 2019 Theresa. All rights reserved.
//

import MetalKit
import Foundation

protocol Frame {
    var position: TimeInterval { get }
    var duration: TimeInterval { get }
}

class MarkerFrame: Frame {
    var position: TimeInterval = -.greatestFiniteMagnitude
    var duration: TimeInterval = -.greatestFiniteMagnitude
}

class AudioFrame: Frame {
    var position: TimeInterval
    var duration: TimeInterval
    
    var samples: UnsafeMutableRawPointer?
    var length: Int = 0
    var outputOffset: Int = 0
    var bufferSize: Int = 0
    
    deinit {
        free(samples)
    }
    
    init(position: TimeInterval, duration: TimeInterval, samplesLength: Int) {
        self.position = position
        self.duration = duration
        if bufferSize < samplesLength {
            if (bufferSize > 0 && samples != nil) {
                free(samples)
            }
            bufferSize = samplesLength
            samples = malloc(bufferSize)
        }
        length = samplesLength
    }

}

class NV12VideoFrame: Frame, RenderDataNV12 {
    let width: Int
    let height: Int
    let pixelBuffer: CVPixelBuffer
    
    let position: TimeInterval
    let duration: TimeInterval
    
    init(position: TimeInterval, duration: TimeInterval, pixelBuffer: CVPixelBuffer) {
        self.position = position
        self.duration = duration
        self.pixelBuffer = pixelBuffer
        self.width = CVPixelBufferGetWidth(pixelBuffer)
        self.height = CVPixelBufferGetHeight(pixelBuffer)
    }
}

class I420VideoFrame: Frame, RenderDataI420 {
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
    
    init(position: TimeInterval, duration: TimeInterval, width: Int, height: Int, frame: YuuFrame) {
        self.position = position
        self.duration = duration
        self.width = width
        self.height = height
        
        let linesize_y = Int(frame.linesize[0])
        let linesize_u = Int(frame.linesize[1])
        let linesize_v = Int(frame.linesize[2])
        
        let needsize_y = YuuYUVChannelFilterNeedSize(width, height, linesize_y)
        let needsize_u = YuuYUVChannelFilterNeedSize(width/2, height/2, linesize_u)
        let needsize_v = YuuYUVChannelFilterNeedSize(width/2, height/2, linesize_v)
        
        luma_channel_pixels = UnsafeMutablePointer<UInt8>.allocate(capacity: needsize_y)
        chromaB_channel_pixels = UnsafeMutablePointer<UInt8>.allocate(capacity: needsize_u)
        chromaR_channel_pixels = UnsafeMutablePointer<UInt8>.allocate(capacity: needsize_v)
        
        YuuYUVChannelFilter(frame.data[0]!, linesize_y, width, height, luma_channel_pixels, needsize_y)
        YuuYUVChannelFilter(frame.data[1]!, linesize_u, width / 2, height / 2, chromaB_channel_pixels, needsize_u)
        YuuYUVChannelFilter(frame.data[2]!, linesize_v, width / 2, height / 2, chromaR_channel_pixels, needsize_v)
    }
    
}
