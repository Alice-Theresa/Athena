//
//  SCRender.h
//  Athena
//
//  Created by Theresa on 2019/01/15.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "Athena-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface SCRender : NSObject

@property (nonatomic, strong) id<MTLDevice> device;

//- (void)render:(id<RenderData>)frame drawIn:(MTKView *)mtkView;

@end

NS_ASSUME_NONNULL_END

