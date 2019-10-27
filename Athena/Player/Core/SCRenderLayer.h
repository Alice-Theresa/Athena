//
//  SCRenderLayer.h
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SCDecoderLayer;
@class SCFormatContext;
@class SCFrameQueue;

@interface SCRenderLayer : NSObject

- (instancetype)initWithContext:(SCFormatContext *)context decoderLayer:(SCDecoderLayer *)decoderLayer renderView:(MTKView *)view;
- (void)start;
- (void)resume;
- (void)pause;
- (void)close;

@end

NS_ASSUME_NONNULL_END
