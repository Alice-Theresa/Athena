//
//  SCVideoFrameQueue.h
//  Athena
//
//  Created by Theresa on 2018/12/28.
//  Copyright © 2018 Theresa. All rights reserved.
//

@class SCVideoFrame;

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCVideoFrameQueue : NSObject

@property (nonatomic, assign, readonly) NSInteger count;

+ (instancetype)shared;
- (void)putFrame:(SCVideoFrame *)frame;
- (SCVideoFrame *)getFrame;

- (void)flush;

@end

NS_ASSUME_NONNULL_END
