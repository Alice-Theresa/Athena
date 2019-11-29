//
//  SCRenderLayer.h
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ALCFrameQueue;
@class ALCFormatContext;

@interface ALCRenderLoop : NSObject

- (instancetype)initWithContext:(ALCFormatContext *)context frameQueue:(ALCFrameQueue *)frameQueue renderView:(MTKView *)view;
- (void)start;
- (void)resume;
- (void)pause;
- (void)close;

@end

NS_ASSUME_NONNULL_END
