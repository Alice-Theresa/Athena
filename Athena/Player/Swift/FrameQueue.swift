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
    
    init(_ frame: Frame) {
        self.frame = frame
    }
}

class FrameQueue {
    
    let semaphore = DispatchSemaphore(value: 1)
    
    private(set) var count = 0
    
    private var header: FrameNode?
    private var tailer: FrameNode?
    
    func enqueueAndSort(frames: Array<Frame>) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        for frame in frames {
            let node = FrameNode(frame)
            guard let tailer = tailer else {
                self.header = node
                self.tailer = node
                count += 1
                continue
            }
            if tailer.frame.position > frame.position {
                guard var search = tailer.pre else { return } //??
                while (search.frame.position > frame.position) {
                    if let pre = search.pre {
                        search = pre
                    } else {
                        break
                    }
                }
                node.next = search.next
                search.next?.pre = node
                node.pre = search
                search.next = node
            } else {
                tailer.next = node;
                node.pre = tailer;
                self.tailer = node;
            }
            count += 1;
        }
    }
    
    func dequeue() -> Frame? {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        var frame: Frame?
        guard let header = header else {
            return frame
        }
        frame = header.frame
        if let next = header.next {
            next.pre = nil
            self.header = next
        } else {
            self.header = nil
            self.tailer = nil
        }
        count -= 1
        return frame
    }
    
    func flush() {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        header = nil
        tailer = nil
        count = 0
    }
    
}
