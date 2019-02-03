//
//  SCRenderDataInterface.h
//  Athena
//
//  Created by Theresa on 2019/01/18.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <libavformat/avformat.h>

NS_ASSUME_NONNULL_BEGIN
/*
@protocol SCRenderDataInterface <NSObject>

@property (nonatomic, assign, readonly) NSUInteger width;
@property (nonatomic, assign, readonly) NSUInteger height;

@end

@protocol SCRenderDataNV12Interface <SCRenderDataInterface>

@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;

- (instancetype)initWithAVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

@protocol SCRenderDataI420Interface <SCRenderDataInterface>

@property (nonatomic, assign, readonly) UInt8 *luma_channel_pixels;
@property (nonatomic, assign, readonly) UInt8 *chromaB_channel_pixels;
@property (nonatomic, assign, readonly) UInt8 *chromaR_channel_pixels;

- (instancetype)initWithFrameData:(AVFrame *)frame width:(int)width height:(int)height;

@end*/

NS_ASSUME_NONNULL_END
