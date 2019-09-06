//
//  Controller.swift
//  Athena
//
//  Created by Theresa on 2019/2/6.
//  Copyright © 2019 Theresa. All rights reserved.
//

import Foundation
import MetalKit

@objc protocol ControllerProtocol: NSObjectProtocol {
    @objc func controlCenter(controller: Controller, didRender position: TimeInterval, duration: TimeInterval)
}

@objc enum ControlState: Int {
    case Origin = 0
    case Opened
    case Playing
    case Paused
    case Closed
}

@objc class Controller: NSObject {
    
    private let context  = FormatContext()
    
    private var vtDecoder: VTDecoder?
    private var ffDecoder: FFDecoder?
    private var videoDecoder: VideoDecoder?
    private var audioDecoder: AudioDecoder?
    
    private let videoFrameQueue = FrameQueue()
    private let audioFrameQueue = FrameQueue()
    private let videoPacketQueue = PacketQueue()
    private let audioPacketQueue = PacketQueue()
    
    private let readPacketOperation = BlockOperation()
    private let videoDecodeOperation = BlockOperation()
    private let audioDecodeOperation = BlockOperation()
    private let controlQueue = OperationQueue()
    
    private weak var mtkView: MTKView?
    private let render = Render()
    @objc weak var delegate: ControllerProtocol?
    
    @objc public private(set) var state: ControlState = .Origin
    
    private var isSeeking = false
    private var videoSeekingTime: TimeInterval = -Double.greatestFiniteMagnitude
    private var audioSeekingTime: TimeInterval = -Double.greatestFiniteMagnitude
    private var syncer = Synchronizer()
    private var videoFrame: Frame?
    private var audioFrame: AudioFrame?
    private var audioManager = AudioManager()
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc init(renderView: MTKView) {
        
        renderView.device = render.device
        renderView.depthStencilPixelFormat = .invalid
        renderView.framebufferOnly = false
        renderView.colorPixelFormat = .bgra8Unorm
        mtkView = renderView

        super.init()
        mtkView!.delegate = self
        audioManager.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc func open(path: NSString) {
        context.open(path: String(path))
//        vtDecoder = VTDecoder(formatContext: context)
        ffDecoder = FFDecoder(formatContext: context)
        videoDecoder = ffDecoder
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
    
    @objc func pause() {
        state = .Paused
        audioManager.stop()
        mtkView?.isPaused = true
    }
    
    @objc func resume() {
        state = .Playing
        audioManager.play()
        mtkView?.isPaused = false
    }
    
    @objc func close() {
        audioManager.stop()
        state = .Closed
        controlQueue.cancelAllOperations()
        controlQueue.waitUntilAllOperationsAreFinished()
        flushQueue()
        context.closeFile()
    }
    
    @objc func seeking(time: TimeInterval) {
        videoSeekingTime = time * context.duration
        audioSeekingTime = videoSeekingTime
        isSeeking = true
    }
    
    @objc func appWillResignActive() {
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
                context.seeking(time: videoSeekingTime)
                flushQueue()
                videoPacketQueue.enqueueDiscardPacket()
                audioPacketQueue.enqueueDiscardPacket()
                isSeeking = false
                continue
            }
            let packet = YuuPacket()
            let result = context.read(packet: packet)
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
                avcodec_flush_buffers(context.videoCodecContext?.cContextPtr)
                videoFrameQueue.flush()
                videoFrameQueue.enqueueAndSort(frames: [MarkerFrame.init()])
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
                avcodec_flush_buffers(context.audioCodecContext?.cContextPtr)
                audioFrameQueue.flush()
                audioFrameQueue.enqueueAndSort(frames: [MarkerFrame.init()])
                packet.unref()
                continue;
            }
            if let ad = audioDecoder, packet.data != nil && packet.streamIndex >= 0 {
                let frames = ad.decode(packet: packet)
                audioFrameQueue.enqueueAndSort(frames: frames)
            }
        }
    }
    
}

extension Controller: MTKViewDelegate {
    func draw(in view: MTKView) {
        if let playFrame = videoFrame {
            if playFrame is MarkerFrame {
                videoSeekingTime = -Double.greatestFiniteMagnitude
                videoFrame = nil
                return
            }
            if videoSeekingTime > 0 {
                videoFrame = nil
                return
            }
            if !syncer.shouldRenderVideoFrame(position: playFrame.position, duration: playFrame.duration) {
                return
            }
            render.render(frame: playFrame as! RenderData, drawIn: mtkView!)
            delegate?.controlCenter(controller: self, didRender: playFrame.position, duration: context.duration)
            videoFrame = nil
        } else {
            videoFrame = videoFrameQueue.dequeue()
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}

extension Controller: AudioManagerDelegate {
    func fetch(outputData: UnsafeMutablePointer<Float>, numberOfFrames: UInt32, numberOfChannels: UInt32) {
        var nof = numberOfFrames
        var od = outputData
        while nof > 0 {
            if let frame = audioFrame {
                if (self.audioSeekingTime > 0) {
                    memset(od, 0, Int(nof * numberOfChannels) * MemoryLayout<Float>.size);
                    self.audioFrame = nil
                    return
                }
                syncer.updateAudioClock(position: frame.position)
                let bytes: UnsafeMutablePointer<UInt8> = frame.samples!.assumingMemoryBound(to: UInt8.self) + frame.outputOffset
                let bytesLeft = frame.length - frame.outputOffset
                let frameSizeOf = Int(numberOfChannels) * MemoryLayout<Float>.size
                let  bytesToCopy = min(Int(nof) * frameSizeOf, bytesLeft)
                let  framesToCopy = bytesToCopy / frameSizeOf
                memcpy(od, bytes, bytesToCopy)
                nof -= UInt32(framesToCopy)
                od = od.advanced(by: framesToCopy * Int(numberOfChannels))
                
                if (bytesToCopy < bytesLeft) {
                    frame.outputOffset += bytesToCopy
                } else {
                    self.audioFrame = nil
                }
            } else if let frame = audioFrameQueue.dequeue() {
                if frame is MarkerFrame {
                    memset(od, 0, Int(nof * numberOfChannels) * MemoryLayout<Float>.size);
                    audioSeekingTime = -Double.greatestFiniteMagnitude
                    self.audioFrame = nil
                } else {
                    self.audioFrame = frame as? AudioFrame
                }
            } else {
                memset(od, 0, Int(nof * numberOfChannels) * MemoryLayout<Float>.size)
            }
        }
    }
    
    
}
