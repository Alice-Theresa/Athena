//
//  Track.swift
//  Athena
//
//  Created by Skylar on 2019/8/22.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

@objc enum TrackType: Int {
    case Video = 0
    case Audio = 1
    case Subtitle = 2
}

@objc class Track : NSObject {
    let type: TrackType
    @objc let index: Int
    let metadata: [String: String]
    
    @objc init(type: TrackType, index: Int, metadata: [String: String]) {
        self.type = type
        self.index = index
        self.metadata = metadata
    }
}
