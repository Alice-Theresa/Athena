//
//  SCControl.h
//  Athena
//
//  Created by Theresa on 2018/12/29.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <MetalKit/MetalKit.h>
#import "ALCPlayerState.h"

@class ALCControl;

@protocol ControlCenterProtocol <NSObject>

- (void)controlCenter:(ALCControl *_Nullable)control didRender:(NSUInteger)position duration:(NSUInteger)duration;

@end

NS_ASSUME_NONNULL_BEGIN

@interface ALCControl : NSObject

@property (nonatomic, assign, readonly) NSTimeInterval currentPosition;
@property (nonatomic, assign, readonly) ALCPlayerState controlState;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRenderView:(UIView *)view;

- (void)openPath:(NSString *)filename;
- (void)pause;
- (void)resume;
- (void)close;

- (void)seekingTime:(NSTimeInterval)percentage;

@end

NS_ASSUME_NONNULL_END
