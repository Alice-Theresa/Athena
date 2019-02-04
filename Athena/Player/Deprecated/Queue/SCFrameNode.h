//
//  SCFrameNode.h
//  Athena
//
//  Created by S.C. on 2019/1/27.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SCFrame;

@interface SCFrameNode : NSObject

@property (nonatomic, strong, readonly) SCFrame *frame;
@property (nonatomic, weak  ) SCFrameNode *pre;
@property (nonatomic, strong) SCFrameNode *next;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(SCFrame *)frame;

@end

NS_ASSUME_NONNULL_END
