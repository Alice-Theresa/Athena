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
    
    private let readPacketOperation: Operation
    private let videoDecodeOperation: Operation
    private let audioDecodeOperation: Operation
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
        
        readPacketOperation = Operation()
        videoDecodeOperation = Operation()
        audioDecodeOperation = Operation()
        controlQueue = OperationQueue()
        
        context = SCFormatContext()
        render = Render()
        super.init()
    }
    
    func open(path: String) {
        
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
