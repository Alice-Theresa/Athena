//
//  Controller.swift
//  Athena
//
//  Created by Theresa on 2019/2/6.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation
import MetalKit

enum ControlState: Int {
    case Origin = 0
    case Opened
    case Playing
    case Paused
    case Closed
}

class Controller: NSObject {
    
    private let context: SCFormatContext
    
    private var VTDecoder: VTDecoder?
    private var FFDecoder: FFDecoder?
    private var videoDecoder: VideoDecoder?
    private var audioDecoder: SCAudioDecoder?
    
    private let videoFrameQueue: FrameQueue
    private let audioFrameQueue: SCFrameQueue
    private let videoPacketQueue: SCPacketQueue
    private let audioPacketQueue: SCPacketQueue
    
    private let readPacketOperation: BlockOperation
    private let videoDecodeOperation: BlockOperation
    private let audioDecodeOperation: BlockOperation
    private let controlQueue: OperationQueue
    
    private weak var mtkView: MTKView?
    private let render: Render
    
    public private(set) var state: ControlState = .Origin
    
    private var isSeeking: Bool
    private var videoSeekingTime: TimeInterval
    
    deinit {
        
    }
    
    init(renderView: MTKView) {
        
        mtkView = renderView
        
        videoPacketQueue = SCPacketQueue()
        audioPacketQueue = SCPacketQueue()
        videoFrameQueue = FrameQueue()
        audioFrameQueue = SCFrameQueue()
        
        readPacketOperation = BlockOperation()
        videoDecodeOperation = BlockOperation()
        audioDecodeOperation = BlockOperation()
        controlQueue = OperationQueue()
        
        context = SCFormatContext()
        render = Render()
        isSeeking = false
        videoSeekingTime = 0
        super.init()
    }
    
    func open(path: String) {
        
    }
    
    func start() {
        readPacketOperation.addExecutionBlock {
            
        }
        videoDecodeOperation.addExecutionBlock {
            
        }
        audioDecodeOperation.addExecutionBlock {
            
        }
        controlQueue.addOperation(readPacketOperation)
        controlQueue.addOperation(videoDecodeOperation)
        controlQueue.addOperation(audioDecodeOperation)
    }
    
    func pause() {
        
    }
    
    func resume() {
        
    }
    
    func close() {
        state = .Closed
        controlQueue.cancelAllOperations()
        controlQueue.waitUntilAllOperationsAreFinished()
        flushQueue()
        context.closeFile()
    }
    
    func seeking(time: TimeInterval) {
        
    }
    
    func appWillResignActive() {
        pause()
    }
    
    func flushQueue() {
        videoFrameQueue.flush()
        audioFrameQueue.flush()
        videoPacketQueue.flush()
        audioPacketQueue.flush()
    }
    
    func readPacket() {
        var finished = false
        while !finished {
            if state == .Closed {
                break
            }
            if state == .Paused {
                Thread.sleep(forTimeInterval: 0.03)
                continue
            }
            if videoPacketQueue.packetTotalSize + audioPacketQueue.packetTotalSize > 10 * 1024 * 1024 {
                Thread.sleep(forTimeInterval: 0.03)
                continue
            }
            if isSeeking {
                context.seekingTime(videoSeekingTime)
                flushQueue()
                videoPacketQueue.enqueueDiscardPacket()
                audioPacketQueue.enqueueDiscardPacket()
                isSeeking = false
                continue
            }
            let packet: UnsafeMutablePointer<AVPacket> = av_packet_alloc()
            let result = context.readFrame(packet)
            if result < 0 {
                finished = true
                break
            } else {
                if packet.pointee.stream_index == context.videoIndex {
                    videoPacketQueue.enqueue(packet.pointee)
                } else if packet.pointee.stream_index == context.audioIndex {
                    audioPacketQueue.enqueue(packet.pointee)
                }
            }
        }
    }
    
    func decodeVideoFrame() {
        while state != .Closed {
            if state == .Paused {
                Thread.sleep(forTimeInterval: 0.03)
                continue
            }
            if videoFrameQueue.count > 10 {
                Thread.sleep(forTimeInterval: 0.03)
                continue
            }
            var packet = videoPacketQueue.dequeuePacket()
            if packet.flags == AV_PKT_FLAG_DISCARD {
                avcodec_flush_buffers(context.videoCodecContext)
                videoFrameQueue.flush()
                videoFrameQueue.enqueueAndSort(frames: NSArray.init(object: MarkerFrame.init()))
                av_packet_unref(&packet);
                continue;
            }
            if packet.data != nil && packet.stream_index >= 0 {
                let frames = videoDecoder!.decode(packet: packet)
                videoFrameQueue.enqueueAndSort(frames: frames)
            }
        }
    }
    
    func rendering() {
        
    }
}

extension Controller: MTKViewDelegate {
    func draw(in view: MTKView) {
        rendering()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
