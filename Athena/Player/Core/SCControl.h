//
//  SCControl.h
//  Athena
//
//  Created by Theresa on 2018/12/29.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <MetalKit/MetalKit.h>

typedef NS_ENUM(NSUInteger, SCControlState) {
    SCControlStateOrigin = 0,
    SCControlStatePlaying,
    SCControlStatePaused,
    SCControlStateClosed
};

@class SCControl;

@protocol ControlCenterProtocol <NSObject>

- (void)controlCenter:(SCControl *_Nullable)control didRender:(NSUInteger)position duration:(NSUInteger)duration;

@end

NS_ASSUME_NONNULL_BEGIN

@interface SCControl : NSObject

@property (nonatomic, assign, readonly) SCControlState controlState;
//@property (nonatomic, weak) id<ControlCenterProtocol> delegate;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRenderView:(MTKView *)view;

- (void)openPath:(NSString *)filename;
- (void)pause;
- (void)resume;
- (void)close;

- (void)seekingTime:(NSTimeInterval)percentage;

@end

NS_ASSUME_NONNULL_END
