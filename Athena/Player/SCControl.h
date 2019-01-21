//
//  SCControl.h
//  Athena
//
//  Created by Theresa on 2018/12/29.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <MetalKit/MetalKit.h>

@class SCFormatContext;
@class SCFrameQueue;

NS_ASSUME_NONNULL_BEGIN

@interface SCControl : NSObject

@property (nonatomic, strong, readonly) SCFrameQueue *videoFrameQueue;
@property (nonatomic, strong, readonly) SCFrameQueue *audioFrameQueue;

@property (nonatomic, assign, readonly) BOOL isPlaying;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRenderView:(MTKView *)view;

- (void)open;

- (void)pause;
- (void)resume;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
