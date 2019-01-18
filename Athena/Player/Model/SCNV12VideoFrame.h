//
//  SCNV12VideoFrame.h
//  Athena
//
//  Created by Theresa on 2018/12/28.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "SCFrame.h"
#import "SCRenderDataInterface.h"

NS_ASSUME_NONNULL_BEGIN

@interface SCNV12VideoFrame : SCFrame <SCRenderDataNV12Interface>

@property (nonatomic, assign, readonly) NSUInteger width;
@property (nonatomic, assign, readonly) NSUInteger height;

@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
