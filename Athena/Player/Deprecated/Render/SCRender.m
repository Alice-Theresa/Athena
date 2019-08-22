//
//  SCRender.m
//  Athena
//
//  Created by Theresa on 2019/01/15.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <AVFoundation/AVUtilities.h>
#import "SCRender.h"
#import "Athena-Swift.h"
#import "SCShaderType.h"

@interface SCRender ()

@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLLibrary> library;
@property (nonatomic, strong) MTLRenderPipelineDescriptor *nv12PipelineDescriptor;
@property (nonatomic, strong) MTLRenderPipelineDescriptor *yuvPipelineDescriptor;

@property (nonatomic, assign) CVMetalTextureRef yTextureRef;
@property (nonatomic, assign) CVMetalTextureRef uvTextureRef;

@end

@implementation SCRender

- (instancetype)init {
    if (self = [super init]) {
        _device = MTLCreateSystemDefaultDevice();
        _commandQueue = [_device newCommandQueue];
        _library = [_device newDefaultLibrary];
    }
    return self;
}
/*
- (void)render:(id<RenderData>)frame drawIn:(MTKView *)mtkView {
    if ([frame conformsToProtocol:@protocol(RenderDataNV12)]) {
        [self renderNV12:(id<RenderDataNV12>)frame drawIn:mtkView];
    } else if ([frame conformsToProtocol:@protocol(RenderDataI420)]) {
        [self renderI420:(id<RenderDataI420>)frame drawIn:mtkView];
    } else {
        NSLog(@"error: no corresponding method");
    }
}

- (void)renderNV12:(id<RenderDataNV12>)frame drawIn:(MTKView *)mtkView {
    CVMetalTextureCacheRef textureCache;
    CVMetalTextureCacheCreate(0, nil, self.device, nil, &textureCache);
    
    size_t width = frame.width;
    size_t height = frame.height;
    
    CVReturn code = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                              textureCache,
                                              frame.pixelBuffer,
                                              nil,
                                              MTLPixelFormatR8Unorm,
                                              CVPixelBufferGetWidthOfPlane(frame.pixelBuffer, 0),
                                              CVPixelBufferGetHeightOfPlane(frame.pixelBuffer, 0),
                                              0,
                                              &_yTextureRef);
    if (code != kCVReturnSuccess) {
        NSLog(@"code: %d", code);
    }
    id<MTLTexture> yTexture = CVMetalTextureGetTexture(self.yTextureRef);
    code = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                              textureCache,
                                              frame.pixelBuffer,
                                              nil,
                                              MTLPixelFormatRG8Unorm,
                                              CVPixelBufferGetWidthOfPlane(frame.pixelBuffer, 1),
                                              CVPixelBufferGetHeightOfPlane(frame.pixelBuffer, 1),
                                              1,
                                              &_uvTextureRef);
    if (code != kCVReturnSuccess) {
        NSLog(@"code: %d", code);
    }
    id<MTLTexture> uvTexture = CVMetalTextureGetTexture(self.uvTextureRef);

    MTLRenderPassDescriptor *descriptor = [mtkView currentRenderPassDescriptor];
    id<CAMetalDrawable> currentDrawable = [mtkView currentDrawable];
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:descriptor];
    
    [encoder setRenderPipelineState:[self.device newRenderPipelineStateWithDescriptor:self.nv12PipelineDescriptor error:nil]];
    [encoder setVertexBuffer:[self createBuffer:CGSizeMake(width, height) viewBounds:mtkView.bounds] offset:0 atIndex:0];
    [encoder setFragmentTexture:yTexture atIndex:SCTextureIndexY];
    [encoder setFragmentTexture:uvTexture atIndex:SCTextureIndexUV];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4 instanceCount:1];
    [encoder endEncoding];
    [commandBuffer presentDrawable:currentDrawable];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted]; //fix screen tearing problem or flush texture at the very beinging
    
    [self flushTexture];
    CVMetalTextureCacheFlush(textureCache, 0);
    if(textureCache) {
        CFRelease(textureCache);
    }
}

- (void)renderI420:(id<RenderDataI420>)frame drawIn:(MTKView *)mtkView {
    size_t width = frame.width;
    size_t height = frame.height;
    
    MTLRegion yRegion = { { 0, 0, 0 }, { width, height, 1 } };
    MTLRegion uvRegion = { { 0, 0, 0 }, { width / 2, height / 2, 1 } };
    
    MTLTextureDescriptor *yDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm width:width height:height mipmapped:YES];
    MTLTextureDescriptor *uvDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm width:width / 2 height:height / 2 mipmapped:YES];
    
    id<MTLTexture> yTexture = [self.device newTextureWithDescriptor:yDesc];
    id<MTLTexture> uTexture = [self.device newTextureWithDescriptor:uvDesc];
    id<MTLTexture> vTexture = [self.device newTextureWithDescriptor:uvDesc];
    [yTexture replaceRegion:yRegion mipmapLevel:0 withBytes:frame.luma_channel_pixels bytesPerRow:width];
    [uTexture replaceRegion:uvRegion mipmapLevel:0 withBytes:frame.chromaB_channel_pixels bytesPerRow:width / 2];
    [vTexture replaceRegion:uvRegion mipmapLevel:0 withBytes:frame.chromaR_channel_pixels bytesPerRow:width / 2];
    
    MTLRenderPassDescriptor *descriptor = [mtkView currentRenderPassDescriptor];
    id<CAMetalDrawable> currentDrawable = [mtkView currentDrawable];
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:descriptor];
    
    [encoder setRenderPipelineState:[self.device newRenderPipelineStateWithDescriptor:self.yuvPipelineDescriptor error:nil]];
    [encoder setVertexBuffer:[self createBuffer:CGSizeMake(width, height) viewBounds:mtkView.bounds] offset:0 atIndex:0];
    [encoder setFragmentTexture:yTexture atIndex:SCTextureIndexY];
    [encoder setFragmentTexture:uTexture atIndex:SCTextureIndexU];
    [encoder setFragmentTexture:vTexture atIndex:SCTextureIndexV];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4 instanceCount:1];
    [encoder endEncoding];
    [commandBuffer presentDrawable:currentDrawable];
    [commandBuffer commit];
}

- (id<MTLBuffer>)createBuffer:(CGSize)contentSize viewBounds:(CGRect)viewBounds {
    CGRect vertexSamplingRect     = AVMakeRectWithAspectRatioInsideRect(contentSize, viewBounds);
    CGSize cropScaleAmount        = CGSizeMake(vertexSamplingRect.size.width / viewBounds.size.width, vertexSamplingRect.size.height / viewBounds.size.height);
    CGSize normalizedSamplingSize = CGSizeMake(0.0, 0.0);
    
    if (cropScaleAmount.width > cropScaleAmount.height) {
        normalizedSamplingSize.width = 1.0;
        normalizedSamplingSize.height = cropScaleAmount.height / cropScaleAmount.width;
    } else {
        normalizedSamplingSize.width = cropScaleAmount.width / cropScaleAmount.height;
        normalizedSamplingSize.height = 1.0;;
    }
    SCVertex quadVertices[] =
    {
        { { -1 * normalizedSamplingSize.width, -1 * normalizedSamplingSize.height } },
        { {  1 * normalizedSamplingSize.width, -1 * normalizedSamplingSize.height } },
        { { -1 * normalizedSamplingSize.width,  1 * normalizedSamplingSize.height } },
        { {  1 * normalizedSamplingSize.width,  1 * normalizedSamplingSize.height } }
    };
    NSData *vertexData = [NSData dataWithBytes:&quadVertices length:sizeof(quadVertices)];
    id<MTLBuffer> vertexBuffer = [self.device newBufferWithLength:vertexData.length options:MTLResourceStorageModeShared];
    memcpy(vertexBuffer.contents, vertexData.bytes, vertexData.length);
    return vertexBuffer;
}

- (void)flushTexture {
    if (self.yTextureRef) {
        CFRelease(self.yTextureRef);
        self.yTextureRef = NULL;
    }
    if (self.uvTextureRef) {
        CFRelease(self.uvTextureRef);
        self.uvTextureRef = NULL;
    }
}

- (MTLRenderPipelineDescriptor *)nv12PipelineDescriptor {
    if (!_nv12PipelineDescriptor) {
        _nv12PipelineDescriptor                                 = [[MTLRenderPipelineDescriptor alloc] init];
        _nv12PipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        _nv12PipelineDescriptor.depthAttachmentPixelFormat      = MTLPixelFormatInvalid;
        _nv12PipelineDescriptor.vertexFunction                  = [self.library newFunctionWithName:@"mappingVertex"];
        _nv12PipelineDescriptor.fragmentFunction                = [self.library newFunctionWithName:@"nv12Fragment"];
    }
    return _nv12PipelineDescriptor;
}

- (MTLRenderPipelineDescriptor *)yuvPipelineDescriptor {
    if (!_yuvPipelineDescriptor) {
        _yuvPipelineDescriptor                                 = [[MTLRenderPipelineDescriptor alloc] init];
        _yuvPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        _yuvPipelineDescriptor.depthAttachmentPixelFormat      = MTLPixelFormatInvalid;
        _yuvPipelineDescriptor.vertexFunction                  = [self.library newFunctionWithName:@"mappingVertex"];
        _yuvPipelineDescriptor.fragmentFunction                = [self.library newFunctionWithName:@"i420Fragment"];
    }
    return _yuvPipelineDescriptor;
}
*/
@end
