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

class MarkerFrame: NSObject, Frame {
    var position: TimeInterval = -.greatestFiniteMagnitude
    var duration: TimeInterval = -.greatestFiniteMagnitude
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

class I420VideoFrame: NSObject, Frame {
    let position: TimeInterval
    let duration: TimeInterval
    
    init(position: TimeInterval, duration: TimeInterval) {
        self.position = position
        self.duration = duration
    }
}
