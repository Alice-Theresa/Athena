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

@objc class Controller: NSObject {
    
    private let context: SCFormatContext
    
    private var vtDecoder: VTDecoder?
    private var ffDecoder: FFDecoder?
    private var videoDecoder: VideoDecoder?
    private var audioDecoder: AudioDecoder?
    
    private let videoFrameQueue: FrameQueue
    private let audioFrameQueue: FrameQueue
    private let videoPacketQueue: PacketQueue
    private let audioPacketQueue: PacketQueue
    
    private let readPacketOperation: BlockOperation
    private let videoDecodeOperation: BlockOperation
    private let audioDecodeOperation: BlockOperation
    private let controlQueue: OperationQueue
    
    private weak var mtkView: MTKView?
    private let render: Render
    
    public private(set) var state: ControlState = .Origin
    
    private var isSeeking: Bool
    private var videoSeekingTime: TimeInterval
    private var videoFrame: Frame?
    private var audioFrame: AudioFrame?
    private var audioManager: AudioManager
    
    deinit {
        
    }
    
    @objc init(renderView: MTKView) {
        
        videoPacketQueue = PacketQueue()
        audioPacketQueue = PacketQueue()
        videoFrameQueue = FrameQueue()
        audioFrameQueue = FrameQueue()
        
        readPacketOperation = BlockOperation()
        videoDecodeOperation = BlockOperation()
        audioDecodeOperation = BlockOperation()
        controlQueue = OperationQueue()
        
        context = SCFormatContext()
        render = Render()
        isSeeking = false
        videoSeekingTime = 0
        
        mtkView = renderView
        mtkView!.device = render.device
        mtkView!.depthStencilPixelFormat = .invalid
        mtkView!.framebufferOnly = false
        mtkView!.colorPixelFormat = .bgra8Unorm

        audioManager = AudioManager()
        super.init()
        mtkView!.delegate = self
        audioManager.delegate = self
    }
    
    @objc func open(path: NSString) {
        context.openPath(String(path))
        vtDecoder = VTDecoder(formatContext: context)
        videoDecoder = vtDecoder
        audioDecoder = AudioDecoder(formatContext: context)
        start()
    }
    
    func start() {
        readPacketOperation.addExecutionBlock {
            self.readPacket()
        }
        videoDecodeOperation.addExecutionBlock {
            self.decodeVideoFrame()
        }
        audioDecodeOperation.addExecutionBlock {
            self.decodeAudioFrame()
        }
        controlQueue.addOperation(readPacketOperation)
        controlQueue.addOperation(videoDecodeOperation)
        controlQueue.addOperation(audioDecodeOperation)
        audioManager.play()
    }
    
    func pause() {
        
    }
    
    func resume() {
        
    }
    
    @objc func close() {
        audioManager.stop()
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
            if videoPacketQueue.packetTotalSize + Int(audioPacketQueue.packetTotalSize) > 10 * 1024 * 1024 {
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
            let packet = YuuPacket()
            let result = context.readFrame(packet.cPacketPtr)
            if result < 0 {
                finished = true
                break
            } else {
                if packet.streamIndex == context.videoIndex {
                    videoPacketQueue.enqueue(packet: packet)
                } else if packet.streamIndex == context.audioIndex {
                    audioPacketQueue.enqueue(packet: packet)
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
            let packet = videoPacketQueue.dequeue()
            if packet.flags == .discard {
                avcodec_flush_buffers(context.videoCodecContext)
                videoFrameQueue.flush()
                videoFrameQueue.enqueueAndSort(frames: NSArray.init(object: MarkerFrame.init()))
                packet.unref()
                continue
            }
            if let vd = videoDecoder, packet.data != nil && packet.streamIndex >= 0 {
                let frames = vd.decode(packet: packet)
                videoFrameQueue.enqueueAndSort(frames: frames)
            }
        }
    }
    
    func decodeAudioFrame() {
        while state != .Closed {
            if state == .Paused {
                Thread.sleep(forTimeInterval: 0.03)
                continue
            }
            if audioFrameQueue.count > 10 {
                Thread.sleep(forTimeInterval: 0.03)
                continue
            }
            let packet = audioPacketQueue.dequeue()
            if packet.flags == .discard {
                avcodec_flush_buffers(context.audioCodecContext)
                audioFrameQueue.flush()
                audioFrameQueue.enqueueAndSort(frames: NSArray.init(object: MarkerFrame.init()))
                packet.unref()
                continue;
            }
            if let ad = audioDecoder, packet.data != nil && packet.streamIndex >= 0 {
                let frames = ad.decode(packet: packet)
                audioFrameQueue.enqueueAndSort(frames: frames)
            }
        }
    }
    
    func rendering() {
        if let playFrame = videoFrame {
            if playFrame.isMember(of: MarkerFrame.self) {
                videoSeekingTime = -1
                videoFrame = nil
                return
            }
            if videoSeekingTime > 0 {
                videoFrame = nil
                return
            }
            render.render(frame: playFrame as! RenderData, drawIn: mtkView!)
            videoFrame = nil
        } else {
            videoFrame = videoFrameQueue.dequeue()
            if videoFrame == nil {
                return
            }
        }
    }
}

extension Controller: MTKViewDelegate {
    func draw(in view: MTKView) {
        rendering()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}

extension Controller: AudioManagerDelegate {
    func fetch(outputData: UnsafeMutablePointer<Float>, numberOfFrames: UInt32, numberOfChannels: UInt32) {
        var nof = numberOfFrames
        var od = outputData
        while nof > 0 {
            if let frame = audioFrame {
                if frame.duration == -1 {
                    memset(od, 0, Int(nof * numberOfChannels) * MemoryLayout<Float>.size);
//                    audioSeekingTime = -DBL_MAX;
                    audioFrame = nil
                    return
                }
//                if (self.audioSeekingTime > 0) {
//                }
                let bytes: UnsafeMutablePointer<UInt8> = frame.samples!.assumingMemoryBound(to: UInt8.self) + frame.outputOffset
                let bytesLeft = frame.length - frame.outputOffset
                let frameSizeOf = Int(numberOfChannels) * MemoryLayout<Float>.size
                let  bytesToCopy = min(Int(nof) * frameSizeOf, bytesLeft)
                let  framesToCopy = bytesToCopy / frameSizeOf
                memcpy(od, bytes, bytesToCopy)
                nof = nof - UInt32(framesToCopy)
                od = od.advanced(by: framesToCopy * Int(numberOfChannels))
                
                if (bytesToCopy < bytesLeft) {
                    frame.outputOffset = frame.outputOffset + bytesToCopy
                } else {
                    audioFrame = nil
                }
            } else {
                if let af = audioFrameQueue.dequeue() {
                    self.audioFrame = af as? AudioFrame
                } else {
                    memset(od, 0, Int(numberOfFrames * numberOfChannels) * MemoryLayout<Float>.size)
                    return
                }
            }
        }
    }
    
    
}
