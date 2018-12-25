//
//  VideoDecoder.h
//  Athena
//
//  Created by Theresa on 2018/12/24.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol VideoDecoderDelegate <NSObject>

- (void)fetch:(CVPixelBufferRef)buffer;

@end

@interface VideoHardwareDecoder : NSObject

@property (nonatomic, weak) id<VideoDecoderDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithStream:(NSInputStream *)stream;

- (void)startDecode;
- (void)stopDecode;
- (void)decodeFrame;

@end

NS_ASSUME_NONNULL_END
