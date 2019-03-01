//
//  PacketQueue.swift
//  Athena
//
//  Created by Theresa on 2019/2/4.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation

fileprivate class PacketNode {
    let packet: NSValue
    var next: PacketNode?
    
    init(_ packet: NSValue) {
        self.packet = packet
    }
}

@objc public class PacketQueue: NSObject {
    let semaphore = DispatchSemaphore(value: 1)
    
    @objc public private(set) var packetTotalSize = 0
    
    private var header: PacketNode?
    private var tailer: PacketNode?
    
    @objc(enqueueDiscardPacket)
    func enqueueDiscardPacket() {
        
    }
    
    func enqueue(Packet: AVPacket) {
        
    }
    
    func dequeue() -> AVPacket {
        fatalError()
    }
    
    func flush() {
        semaphore.wait()
        if let header = header {
            var packet: AVPacket?
            header.packet.getValue(&packet)
            if var packet = packet {
                av_packet_unref(&packet)
            }
            while let next = header.next {
                next.packet.getValue(&packet)
                if var packet = packet {
                    av_packet_unref(&packet)
                }
                self.header = next
            }
        }
        packetTotalSize = 0
        semaphore.signal()
    }
}
