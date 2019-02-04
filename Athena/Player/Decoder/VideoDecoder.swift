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
    
    func decode(packet: AVPacket) -> NSArray {
        fatalError()
    }
    
    static func CFDictionarySetObject(dict: CFMutableDictionary, key: UnsafeRawPointer, value: UnsafeRawPointer) {
        CFDictionarySetValue(dict, key, value)
    }
}

//class FFDecoder: VideoDecoder {
//
//}
