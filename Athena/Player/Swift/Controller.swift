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
        
    }
    
    func seeking(time: TimeInterval) {
        
    }
    
    func appWillResignActive() {
        pause()
    }
}

extension Controller: MTKViewDelegate {
    func draw(in view: MTKView) {
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
