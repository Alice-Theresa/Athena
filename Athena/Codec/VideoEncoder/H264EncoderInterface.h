//
//  H264EncoderInterface.h
//  Athena
//
//  Created by Theresa on 2017/10/20.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol H264EncoderInterface <NSObject>

/**
 禁用初始化方法
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 标准初始化方法
 
 @param encoderQueue 编码队列
 @param callbackQueue 回调队列
 @return 编码器
 */
- (instancetype)initWithEncoderQueue:(dispatch_queue_t)encoderQueue callbackQueue:(dispatch_queue_t)callbackQueue;

/**
 使用编码器进行H264编码
 
 @param sampleBuffer 相机原始数据
 */
- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
