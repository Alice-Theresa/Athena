//
//  PacketQueue.swift
//  Athena
//
//  Created by Theresa on 2019/2/4.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

fileprivate class PacketNode {
    let packet: YuuPacket
    var next: PacketNode?
    
    init(_ packet: YuuPacket) {
        self.packet = packet
    }
}

class PacketQueue: NSObject {
    
    let semaphore = DispatchSemaphore(value: 1)
    
    var packetTotalSize = 0
    
    var queue: [YuuPacket] = []
    
    private var header: PacketNode?
    private var tailer: PacketNode?
    
    func enqueueDiscardPacket() {
        let packet = YuuPacket()
        packet.flags = .discard
        enqueue(packet: packet)
    }
    
    func enqueue(packet: YuuPacket) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        packetTotalSize += Int(packet.size)
        let node = PacketNode(packet)
        if let tailer = tailer {
            tailer.next = node
            self.tailer = node
        } else {
            header = node
            tailer = node
        }
    }
    
    func dequeue() -> YuuPacket {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        var packet = YuuPacket()
        packet.streamIndex = -1
        if let header = header {
            packet = header.packet
            packetTotalSize -= Int(packet.size)
            if let next = header.next {
                self.header = next
            } else {
                self.header = nil
                self.tailer = nil
            }
        }
        return packet
    }
    
    func flush() {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        if var header = header {
            header.packet.unref()
            while let next = header.next {
                next.packet.unref()
                header = next
            }
        }
        packetTotalSize = 0
    }
}
