//
//  SCVideoFrame.h
//  Athena
//
//  Created by Skylar on 2019/11/8.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface SCVideoFrame : SCFrame

@property (nonatomic, assign, readonly) NSUInteger width;
@property (nonatomic, assign, readonly) NSUInteger height;

@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;

- (uint8_t **)data;
- (void)fillData;

@end

NS_ASSUME_NONNULL_END
