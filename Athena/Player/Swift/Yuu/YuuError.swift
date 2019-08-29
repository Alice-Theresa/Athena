//
//  YuuError.swift
//  Athena
//
//  Created by Skylar on 2019/8/21.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

struct YuuError: Error, Equatable {
    
    let code: Int32
    
    init(code: Int32) {
        self.code = code
    }
}


func throwIfFail(_ condition: @autoclosure () -> Int32) throws {
    let code = condition()
    if code < 0 {
        throw YuuError(code: code)
    }
}

extension Dictionary where Key == String, Value == String {
    
    func toAVDict() -> OpaquePointer? {
        var pm: OpaquePointer?
        for (k, v) in self {
            av_dict_set(&pm, k, v, 0)
        }
        return pm
    }
}

func dumpUnrecognizedOptions(_ dict: OpaquePointer?) {
    var prev: UnsafeMutablePointer<AVDictionaryEntry>?
    while let tag = av_dict_get(dict, "", prev, AV_DICT_IGNORE_SUFFIX) {
//        AVLog.log(level: .warning, message: "Option '\(String(cString: tag.pointee.key!))' not found.")
        prev = tag
    }
}
