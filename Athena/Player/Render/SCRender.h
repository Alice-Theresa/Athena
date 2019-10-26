//
//  SCRender.h
//  Athena
//
//  Created by Theresa on 2019/01/15.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "SCRenderDataInterface.h"

NS_ASSUME_NONNULL_BEGIN

@class SCVideoFrame;

@interface SCRender : NSObject

@property (nonatomic, strong) id<MTLDevice> device;

- (void)render:(SCVideoFrame *)frame drawIn:(MTKView *)mtkView;

@end

NS_ASSUME_NONNULL_END

