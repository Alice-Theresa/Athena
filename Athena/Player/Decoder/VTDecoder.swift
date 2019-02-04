//
//  VTDecoder.swift
//  Athena
//
//  Created by Theresa on 2019/2/4.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation
import VideoToolbox

class VTDecoder {
    weak var formatContext: SCFormatContext?
    
    var session: VTDecompressionSession?
    var formatDescription: CMVideoFormatDescription?
    
    deinit {
        if let session = session {
            VTDecompressionSessionWaitForAsynchronousFrames(session)
            VTDecompressionSessionInvalidate(session)
        }
    }
    
    init(formatContext: SCFormatContext) {
        self.formatContext = formatContext
    }
    
    static func CFDictionarySetObject(dict: CFMutableDictionary, key: UnsafeRawPointer, value: UnsafeRawPointer) {
        CFDictionarySetValue(dict, key, value)
    }
}
