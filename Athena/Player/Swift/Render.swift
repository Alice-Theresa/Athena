//
//  Render.swift
//  Yuu
//
//  Created by Theresa on 2019/2/3.
//  Copyright © 2019 Theresa. All rights reserved.
//

import AVFoundation
import Foundation
import MetalKit

@objc public protocol RenderData: NSObjectProtocol {
    var width: Int { get }
    var height: Int { get }
}

@objc public protocol RenderDataNV12: RenderData {
    var pixelBuffer: CVPixelBuffer { get }
}

@objc public protocol RenderDataI420: RenderData {
    var luma_channel_pixels: UnsafeMutablePointer<UInt8> { get }
    var chromaB_channel_pixels: UnsafeMutablePointer<UInt8> { get }
    var chromaR_channel_pixels: UnsafeMutablePointer<UInt8> { get }
}

@objc public class Render: NSObject {
    @objc public let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary
    
    private var textureCache: CVMetalTextureCache?
    
    private lazy var nv12PipelineDescriptor: MTLRenderPipelineDescriptor = {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.vertexFunction = library.makeFunction(name: "mappingVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "nv12Fragment")
        return descriptor
    }()
    
    private lazy var yuvPipelineDescriptor:MTLRenderPipelineDescriptor = {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.vertexFunction = library.makeFunction(name: "mappingVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "i420Fragment")
        return descriptor
    }()
    
    public override init() {
        device = MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()!
        library = device.makeDefaultLibrary()!
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
    }
    
    @objc(render:drawIn:)
    public func render(frame: RenderData, drawIn view: MTKView) {
        if let frame = frame as? RenderDataNV12 {
            renderNV12(frame, drawIn: view)
        } else if let frame = frame as? RenderDataI420 {
            renderI420(frame, drawIn: view)
        } else {
            fatalError()
        }
    }
    
    private func renderNV12(_ frame: RenderDataNV12, drawIn view: MTKView) {
        guard let _textureCache = textureCache else { return }
        
        let width = frame.width
        let height = frame.height
        
        var yTexture: CVMetalTexture?
        var uvTexture: CVMetalTexture?
        
        var result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                               _textureCache,
                                                               frame.pixelBuffer,
                                                               nil,
                                                               .r8Unorm,
                                                               CVPixelBufferGetWidthOfPlane(frame.pixelBuffer, 0),
                                                               CVPixelBufferGetHeightOfPlane(frame.pixelBuffer, 0),
                                                               0,
                                                               &yTexture)
        if (result != kCVReturnSuccess) {
            print(result)
        }
        result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _textureCache,
                                                           frame.pixelBuffer,
                                                           nil,
                                                           .rg8Unorm,
                                                           CVPixelBufferGetWidthOfPlane(frame.pixelBuffer, 1),
                                                           CVPixelBufferGetHeightOfPlane(frame.pixelBuffer, 1),
                                                           1,
                                                           &uvTexture)
        if (result != kCVReturnSuccess) {
            print(result)
        }
        let textureV = CVMetalTextureGetTexture(yTexture!)
        let textureUV = CVMetalTextureGetTexture(uvTexture!)
        guard let descriptor = view.currentRenderPassDescriptor,
            let currentDrawable = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        
        encoder.setRenderPipelineState(try! device.makeRenderPipelineState(descriptor: nv12PipelineDescriptor))
        encoder.setVertexBuffer(createBuffer(contentSize: CGSize(width: width, height: height), viewBounds: view.bounds), offset: 0, index: 0)
        encoder.setFragmentTexture(textureV, index: Int(SCTextureIndexY.rawValue))
        encoder.setFragmentTexture(textureUV, index: Int(SCTextureIndexUV.rawValue))
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        CVMetalTextureCacheFlush(_textureCache, 0)
    }
    
    private func renderI420(_ frame: RenderDataI420, drawIn view: MTKView) {
        let width = frame.width
        let height = frame.height
        let yRegion = MTLRegionMake3D(0, 0, 0, width, height, 1)
        let uvRegion = MTLRegionMake3D(0, 0, 0, width / 2, height / 2 , 1)
        
        let yDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm, width: width, height: height, mipmapped: true)
        let uvDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm, width: width / 2, height: height / 2, mipmapped: true)
        let yTexture = device.makeTexture(descriptor: yDescriptor)
        let uTexture = device.makeTexture(descriptor: uvDescriptor)
        let vTexture = device.makeTexture(descriptor: uvDescriptor)
        
        yTexture?.replace(region: yRegion, mipmapLevel: 0, withBytes: frame.luma_channel_pixels, bytesPerRow: width)
        uTexture?.replace(region: uvRegion, mipmapLevel: 0, withBytes: frame.chromaB_channel_pixels, bytesPerRow: width / 2)
        vTexture?.replace(region: uvRegion, mipmapLevel: 0, withBytes: frame.chromaR_channel_pixels, bytesPerRow: width / 2)
        
        guard let descriptor = view.currentRenderPassDescriptor,
            let currentDrawable = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        
        encoder.setRenderPipelineState(try! device.makeRenderPipelineState(descriptor: yuvPipelineDescriptor))
        encoder.setVertexBuffer(createBuffer(contentSize: CGSize(width: width, height: height), viewBounds: view.bounds), offset: 0, index: 0)
        encoder.setFragmentTexture(yTexture, index: Int(SCTextureIndexY.rawValue))
        encoder.setFragmentTexture(uTexture, index: Int(SCTextureIndexU.rawValue))
        encoder.setFragmentTexture(vTexture, index: Int(SCTextureIndexV.rawValue))
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
    
    private func createBuffer(contentSize: CGSize ,viewBounds: CGRect) -> MTLBuffer? {
        let vertexSamplingRect = AVMakeRect(aspectRatio: contentSize, insideRect: viewBounds)
        let cropScaleAmount = CGSize(width: vertexSamplingRect.size.width / viewBounds.size.width, height: vertexSamplingRect.size.height / viewBounds.size.height)
        var normalizedSamplingSize = CGSize.zero
        
        if (cropScaleAmount.width > cropScaleAmount.height) {
            normalizedSamplingSize.width = 1.0
            normalizedSamplingSize.height = cropScaleAmount.height / cropScaleAmount.width
        } else {
            normalizedSamplingSize.width = cropScaleAmount.width / cropScaleAmount.height
            normalizedSamplingSize.height = 1.0
        }
        
        let quadVertices: [SCVertex] = [SCVertex(position: float2(Float(-1 * normalizedSamplingSize.width), Float(-1 * normalizedSamplingSize.height))),
                                      SCVertex(position: float2(Float( 1 * normalizedSamplingSize.width), Float(-1 * normalizedSamplingSize.height))),
                                      SCVertex(position: float2(Float(-1 * normalizedSamplingSize.width), Float( 1 * normalizedSamplingSize.height))),
                                      SCVertex(position: float2(Float( 1 * normalizedSamplingSize.width), Float( 1 * normalizedSamplingSize.height)))]
        var vertexData = Data(bytes: quadVertices, count: MemoryLayout.size(ofValue: quadVertices))
        let vertexBuffer = self.device.makeBuffer(bytes: quadVertices, length: vertexData.count * 4, options: .storageModeShared)
        return vertexBuffer
    }
}
