//
//  SCMetalManager.m
//  Athena
//
//  Created by Theresa on 2019/01/15.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCMetalManager.h"

@interface SCMetalManager ()

@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLLibrary> library;

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

- (void)renderTexture:(id<MTLTexture>)texture drawIn:(MTKView *)mtkView {
    MTLRenderPassDescriptor *descriptor = [mtkView currentRenderPassDescriptor];
    id<CAMetalDrawable> currentDrawable = [mtkView currentDrawable];
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:descriptor];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatInvalid;
    pipelineDescriptor.vertexFunction = [self.library newFunctionWithName:@"mappingVertex"];
    pipelineDescriptor.fragmentFunction = [self.library newFunctionWithName:@"mappingFragment"];
    
    
    [encoder setRenderPipelineState:[self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:nil]];
    [encoder setFragmentTexture:texture atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4 instanceCount:1];
    [encoder endEncoding];
    [commandBuffer presentDrawable:currentDrawable];
    [commandBuffer commit];
}

@end
