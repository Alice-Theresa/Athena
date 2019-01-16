//
//  SCMetalManager.m
//  Athena
//
//  Created by Theresa on 2019/01/15.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCMetalManager.h"
#import "SCShaderType.h"

@interface SCMetalManager ()

@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLLibrary> library;
@property (nonatomic, strong) MTLRenderPipelineDescriptor *pipelineDescriptor;


@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, assign) CVMetalTextureRef ytexture;
@property (nonatomic, assign) CVMetalTextureRef uvtexture;

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
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer drawIn:(MTKView *)mtkView {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    CVMetalTextureCacheRef textureCache;
    CVMetalTextureCacheCreate(0, nil, self.device, nil, &textureCache);
    
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    float aspect = (float)width / height;
    AAPLVertex quadVertices[] =
    {
        { { -1.0, -1.0 / 2 / aspect } },
        { {  1.0, -1.0 / 2 / aspect } },
        { { -1.0, 1.0  / 2 / aspect } },
        { {  1.0, 1.0  / 2 / aspect } }
    };
    
    CVReturn code = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                              textureCache,
                                              pixelBuffer,
                                              nil,
                                              MTLPixelFormatR8Unorm,
                                              CVPixelBufferGetWidthOfPlane(pixelBuffer, 0),
                                              CVPixelBufferGetHeightOfPlane(pixelBuffer, 0),
                                              0,
                                              &_ytexture);
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
                                              &_uvtexture);
    if (code != 0) {
        NSLog(@"error");
    }
    id<MTLTexture> yTexture = CVMetalTextureGetTexture(self.ytexture);
    id<MTLTexture> uvTexture = CVMetalTextureGetTexture(self.uvtexture);

    
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
    
    if (_ytexture) {
        CFRelease(_ytexture);
        _ytexture = NULL;
    }
    if (_uvtexture) {
        CFRelease(_uvtexture);
        _uvtexture = NULL;
    }
    CVMetalTextureCacheFlush(textureCache, 0);
    
    if(textureCache) {
        CFRelease(textureCache);
    }
    dispatch_semaphore_signal(_semaphore);
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
