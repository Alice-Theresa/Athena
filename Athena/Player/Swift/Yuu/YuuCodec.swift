//
//  YuuCodec.swift
//  Athena
//
//  Created by Skylar on 2019/8/23.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

class YuuCodec {
    
    let cCodecPtr: UnsafeMutablePointer<AVCodec>
    var cCodec: AVCodec { return cCodecPtr.pointee }
    
    init(cCodecPtr: UnsafeMutablePointer<AVCodec>) {
        self.cCodecPtr = cCodecPtr
    }
    
}

extension YuuCodec {
    
    static func findDecoderById(_ codecId: AVCodecID) -> YuuCodec? {
        guard let codecPtr = avcodec_find_decoder(codecId) else {
            return nil
        }
        return YuuCodec(cCodecPtr: codecPtr)
    }
    
}
