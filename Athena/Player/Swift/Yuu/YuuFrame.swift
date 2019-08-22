//
//  YuuFrame.swift
//  Athena
//
//  Created by Skylar on 2019/8/19.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

@objc final class YuuFrame: NSObject {
    
    let cFramePtr: UnsafeMutablePointer<AVFrame>
    var cFrame: AVFrame { return cFramePtr.pointee }
    
    deinit {
        var ptr: UnsafeMutablePointer<AVFrame>? = cFramePtr
        av_frame_free(&ptr)
    }
    @objc init(cFramePtr: UnsafeMutablePointer<AVFrame>) {
        self.cFramePtr = cFramePtr
    }
    
    @objc override init() {
        guard let framePtr = av_frame_alloc() else {
            fatalError()
        }
        self.cFramePtr = framePtr
    }
    
    var data: UnsafeMutableBufferPointer<UnsafeMutablePointer<UInt8>?> {
        get {
            return withUnsafeMutableBytes(of: &cFramePtr.pointee.data) { ptr in
                return ptr.bindMemory(to: UnsafeMutablePointer<UInt8>?.self)
            }
        }
        set {
            withUnsafeMutableBytes(of: &cFramePtr.pointee.data) { ptr in
                ptr.copyMemory(from: UnsafeRawBufferPointer(newValue))
            }
        }
    }
    
    var linesize: UnsafeMutableBufferPointer<Int32> {
        get {
            return withUnsafeMutableBytes(of: &cFramePtr.pointee.linesize) { ptr in
                return ptr.bindMemory(to: Int32.self)
            }
        }
        set {
            withUnsafeMutableBytes(of: &cFramePtr.pointee.linesize) { ptr in
                ptr.copyMemory(from: UnsafeRawBufferPointer(newValue))
            }
        }
    }
    
    var sampleCount: Int {
        get { return Int(cFrame.nb_samples) }
        set { cFramePtr.pointee.nb_samples = Int32(newValue) }
    }
    
    var repeatPicture: Int {
        return Int(cFrame.repeat_pict)
    }
}
