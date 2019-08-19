//
//  SCFormatContext.swift
//  Athena
//
//  Created by Skylar on 2019/8/19.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

final class YuuFormatContext {
    
    var cContextPtr: UnsafeMutablePointer<AVFormatContext>!
    var cContext: AVFormatContext { return cContextPtr.pointee }
    
    init(cContextPtr: UnsafeMutablePointer<AVFormatContext>) {
        self.cContextPtr = cContextPtr
    }
    
    init() {
        guard let ctxPtr = avformat_alloc_context() else {
            fatalError()
        }
        self.cContextPtr = ctxPtr
    }
}
