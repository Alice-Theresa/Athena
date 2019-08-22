//
//  YuuError.swift
//  Athena
//
//  Created by Skylar on 2019/8/21.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

public struct YuuError: Error, Equatable {
    /// Resource temporarily unavailable
//    public static let tryAgain = YuuError(code: swift_AVERROR(EAGAIN))
//    /// Invalid argument
//    public static let invalidArgument = YuuError(code: swift_AVERROR(EINVAL))
//    /// Cannot allocate memory
//    public static let outOfMemory = YuuError(code: swift_AVERROR(ENOMEM))
//    /// The value is out of range
//    public static let outOfRange = AVError(code: swift_AVERROR(ERANGE))
//    /// The value is not valid
//    public static let invalidValue = AVError(code: swift_AVERROR(EINVAL))
//    /// Function not implemented
//    public static let noSystem = AVError(code: swift_AVERROR(ENOSYS))
//
//    /// Bitstream filter not found
//    public static let bsfNotFound = AVError(code: swift_AVERROR_BSF_NOT_FOUND)
//    /// Internal bug, also see `bug2`
//    public static let bug = AVError(code: swift_AVERROR_BUG)
//    /// Buffer too small
//    public static let bufferTooSmall = AVError(code: swift_AVERROR_BUFFER_TOO_SMALL)
//    /// Decoder not found
//    public static let decoderNotFound = AVError(code: swift_AVERROR_DECODER_NOT_FOUND)
//    /// Demuxer not found
//    public static let demuxerNotFound = AVError(code: swift_AVERROR_DEMUXER_NOT_FOUND)
//    /// Encoder not found
//    public static let encoderNotFound = AVError(code: swift_AVERROR_ENCODER_NOT_FOUND)
//    /// End of file
//    public static let eof = AVError(code: swift_AVERROR_EOF)
//    /// Immediate exit was requested; the called function should not be restarted
//    public static let exit = AVError(code: swift_AVERROR_EXIT)
//    /// Generic error in an external library
//    public static let external = AVError(code: swift_AVERROR_EXTERNAL)
//    /// Filter not found
//    public static let filterNotFound = AVError(code: swift_AVERROR_FILTER_NOT_FOUND)
//    /// Invalid data found when processing input
//    public static let invalidData = AVError(code: swift_AVERROR_INVALIDDATA)
//    /// Muxer not found
//    public static let muxerNotFound = AVError(code: swift_AVERROR_MUXER_NOT_FOUND)
//    /// Option not found
//    public static let optionNotFound = AVError(code: swift_AVERROR_OPTION_NOT_FOUND)
//    /// Not yet implemented in FFmpeg, patches welcome
//    public static let patchWelcome = AVError(code: swift_AVERROR_PATCHWELCOME)
//    /// Protocol not found
//    public static let protocolNotFound = AVError(code: swift_AVERROR_PROTOCOL_NOT_FOUND)
//    /// Stream not found
//    public static let streamNotFound = AVError(code: swift_AVERROR_STREAM_NOT_FOUND)
//    /// This is semantically identical to `bug`. It has been introduced in Libav after our `bug` and
//    /// with a modified value.
//    public static let bug2 = AVError(code: swift_AVERROR_BUG2)
//    /// Unknown error, typically from an external library
//    public static let unknown = AVError(code: swift_AVERROR_UNKNOWN)
//    ///  Requested feature is flagged experimental. Set strict_std_compliance if you really want to use it.
//    public static let experimental = AVError(code: swift_AVERROR_EXPERIMENTAL)
//    /// Input changed between calls. Reconfiguration is required. (can be OR-ed with `outputChanged`)
//    public static let inputChanged = AVError(code: swift_AVERROR_INPUT_CHANGED)
//    /// Output changed between calls. Reconfiguration is required. (can be OR-ed with `inputChanged`)
//    public static let outputChanged = AVError(code: swift_AVERROR_OUTPUT_CHANGED)
//
//    /* HTTP & RTSP errors */
//    public static let httpBadRequest = AVError(code: swift_AVERROR_HTTP_BAD_REQUEST)
//    public static let httpUnauthorized = AVError(code: swift_AVERROR_HTTP_UNAUTHORIZED)
//    public static let httpForbidden = AVError(code: swift_AVERROR_HTTP_FORBIDDEN)
//    public static let httpNotFound = AVError(code: swift_AVERROR_HTTP_NOT_FOUND)
//    public static let httpOther4xx = AVError(code: swift_AVERROR_HTTP_OTHER_4XX)
//    public static let httpServerError = AVError(code: swift_AVERROR_HTTP_SERVER_ERROR)
    
    public let code: Int32
    
    public init(code: Int32) {
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
