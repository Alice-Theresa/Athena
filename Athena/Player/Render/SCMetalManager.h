//
//  SCMetalManager.h
//  Athena
//
//  Created by Theresa on 2019/01/15.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@class SCYUVVideoFrame;

NS_ASSUME_NONNULL_BEGIN

@interface SCMetalManager : NSObject

+ (instancetype)shared;

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, assign) NSUInteger width;
@property (nonatomic, assign) NSUInteger height;

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer drawIn:(MTKView *)mtkView;
- (void)render:(SCYUVVideoFrame *)frame drawIn:(MTKView *)mtkView;

@end

NS_ASSUME_NONNULL_END
