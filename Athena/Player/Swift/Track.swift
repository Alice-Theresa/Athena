//
//  Track.swift
//  Athena
//
//  Created by Skylar on 2019/8/22.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

enum TrackType: Int {
    case Video = 0
    case Audio = 1
    case Subtitle = 2
}

class Track : NSObject {
    let type: TrackType
    let index: Int
    let metadata: [String: String]
    
    init(type: TrackType, index: Int, metadata: [String: String]) {
        self.type = type
        self.index = index
        self.metadata = metadata
    }
}
