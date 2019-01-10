//
//  SCVideoFrame.h
//  Athena
//
//  Created by Theresa on 2018/12/28.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "SCFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface SCVideoFrame : SCFrame

@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;

- (instancetype)initWithAVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
