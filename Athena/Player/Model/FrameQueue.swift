//
//  FrameQueue.swift
//  Athena
//
//  Created by Theresa on 2019/2/3.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

fileprivate class FrameNode {
    let frame: Frame
    weak var pre: FrameNode?
    var next: FrameNode?
    
    init(frame: Frame) {
        self.frame = frame
    }
}

@objc public class FrameQueue: NSObject {
    
    let semaphore = DispatchSemaphore(value: 1)
    
    @objc public private(set) var count = 0
    
    private var header: FrameNode?
    private var tailer: FrameNode?
    
    func enqueueAndSort(frames: Array<Frame>) {
        semaphore.wait()
        
        semaphore.signal()
    }

    func dequeue() -> Frame? {
        semaphore.wait()
        var frame: Frame?
        if var header = header {
            frame = header.frame
            if let next = header.next {
                next.pre = nil
                header = next
            } //??
            count = count - 1
            return frame
        }
        semaphore.signal()
        return frame
    }
    
    func flush() {
        semaphore.wait()
        header = nil
        tailer = nil
        count = 0
        semaphore.signal()
    }
    
}
