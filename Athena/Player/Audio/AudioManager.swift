//
//  AudioManager.swift
//  Athena
//
//  Created by Theresa on 2019/2/6.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

protocol AudioManagerDelegate: NSObjectProtocol {
    func fetch(outputData: UnsafeMutablePointer<Float>, numberOfFrames: UInt32, numberOfChannels: UInt32)
}

class AudioManager: NSObject {
    weak var delegate: AudioManagerDelegate?
    
    private override init() {
        
    }
    
    func play() {
        
    }
    
    func stop() {
        
    }
}
