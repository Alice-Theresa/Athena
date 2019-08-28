//
//  Synchronizer.swift
//  Athena
//
//  Created by Skylar on 2019/8/27.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

class Synchronizer {
    
    private var audioFramePlayTime: TimeInterval = 0
    private var audioFramePosition: TimeInterval = 0
    
    func updateAudioClock(position: TimeInterval) {
        audioFramePlayTime = Date().timeIntervalSince1970
        audioFramePosition = position
    }
    
    func shouldRenderVideoFrame(position: TimeInterval, duration: TimeInterval) -> Bool {
        let time = Date().timeIntervalSince1970
        if (audioFramePosition + time - audioFramePlayTime >= position + duration) {
            return true
        } else {
            return false
        }
    }
}
