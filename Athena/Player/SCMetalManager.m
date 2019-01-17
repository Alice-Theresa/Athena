//
//  SCMetalManager.m
//  Athena
//
//  Created by Theresa on 2019/01/15.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <AVFoundation/AVUtilities.h>
#import "SCMetalManager.h"
#import "SCShaderType.h"

@interface SCMetalManager ()

@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLLibrary> library;
@property (nonatomic, strong) MTLRenderPipelineDescriptor *pipelineDescriptor;

@property (nonatomic, assign) CVMetalTextureRef yTextureRef;
@property (nonatomic, assign) CVMetalTextureRef uvTextureRef;

@end

@implementation SCMetalManager

+ (instancetype)shared {
    static SCMetalManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SCMetalManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _device = MTLCreateSystemDefaultDevice();
        _commandQueue = [_device newCommandQueue];
        _library = [_device newDefaultLibrary];
    }
    return self;
}

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer drawIn:(MTKView *)mtkView {
    //release first or image maybe tears
    if (self.yTextureRef) {
        CFRelease(self.yTextureRef);
        self.yTextureRef = NULL;
    }
    if (self.uvTextureRef) {
        CFRelease(self.uvTextureRef);
        self.uvTextureRef = NULL;
    }
    
    CVMetalTextureCacheRef textureCache;
    CVMetalTextureCacheCreate(0, nil, self.device, nil, &textureCache);
    
    // calculate size
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CGRect viewBounds = mtkView.bounds;
    CGRect vertexSamplingRect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(width, height), viewBounds);
    CGSize normalizedSamplingSize = CGSizeMake(0.0, 0.0);
    CGSize cropScaleAmount = CGSizeMake(vertexSamplingRect.size.width/viewBounds.size.width,
                                        vertexSamplingRect.size.height/viewBounds.size.height);
    if (cropScaleAmount.width > cropScaleAmount.height) {
        normalizedSamplingSize.width = 1.0;
        normalizedSamplingSize.height = cropScaleAmount.height/cropScaleAmount.width;
    }
    else {
        normalizedSamplingSize.width = cropScaleAmount.width/cropScaleAmount.height;
        normalizedSamplingSize.height = 1.0;;
    }
    
    AAPLVertex quadVertices[] =
    {
        { { -1 * normalizedSamplingSize.width, -1 * normalizedSamplingSize.height } },
        { {  1 * normalizedSamplingSize.width, -1 * normalizedSamplingSize.height } },
        { { -1 * normalizedSamplingSize.width,  1 * normalizedSamplingSize.height } },
        { {  1 * normalizedSamplingSize.width,  1 * normalizedSamplingSize.height } }
    };
    
    CVReturn code = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                              textureCache,
                                              pixelBuffer,
                                              nil,
                                              MTLPixelFormatR8Unorm,
                                              CVPixelBufferGetWidthOfPlane(pixelBuffer, 0),
                                              CVPixelBufferGetHeightOfPlane(pixelBuffer, 0),
                                              0,
                                              &_yTextureRef);
    if (code != 0) {
        NSLog(@"error");
    }
    code = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                              textureCache,
                                              pixelBuffer,
                                              nil,
                                              MTLPixelFormatRG8Unorm,
                                              CVPixelBufferGetWidthOfPlane(pixelBuffer, 1),
                                              CVPixelBufferGetHeightOfPlane(pixelBuffer, 1),
                                              1,
                                              &_uvTextureRef);
    if (code != 0) {
        NSLog(@"error");
    }
    id<MTLTexture> yTexture = CVMetalTextureGetTexture(self.yTextureRef);
    id<MTLTexture> uvTexture = CVMetalTextureGetTexture(self.uvTextureRef);

    
    MTLRenderPassDescriptor *descriptor = [mtkView currentRenderPassDescriptor];
    id<CAMetalDrawable> currentDrawable = [mtkView currentDrawable];
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:descriptor];
    
    [encoder setRenderPipelineState:[self.device newRenderPipelineStateWithDescriptor:self.pipelineDescriptor error:nil]];
    [encoder setVertexBytes:quadVertices length:sizeof(quadVertices) atIndex:0];
    [encoder setFragmentTexture:yTexture atIndex:0];
    [encoder setFragmentTexture:uvTexture atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4 instanceCount:1];
    [encoder endEncoding];
    [commandBuffer presentDrawable:currentDrawable];
    [commandBuffer commit];
    
    
    CVMetalTextureCacheFlush(textureCache, 0);
    if(textureCache) {
        CFRelease(textureCache);
    }
}

- (MTLRenderPipelineDescriptor *)pipelineDescriptor {
    if (!_pipelineDescriptor) {
        _pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        _pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        _pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatInvalid;
        _pipelineDescriptor.vertexFunction = [self.library newFunctionWithName:@"mappingVertex"];
        _pipelineDescriptor.fragmentFunction = [self.library newFunctionWithName:@"mappingFragment"];
    }
    return _pipelineDescriptor;
}


@end
