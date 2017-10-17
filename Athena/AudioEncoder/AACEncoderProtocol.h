//
//  AACEncoderProtocol.h
//  Athena
//
//  Created by Theresa on 2017/10/17.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AACEncoderProtocol <NSObject>

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
 使用编码器进行AAC编码
 
 @param sampleBuffer 麦克风原始数据
 @param completionBlock 回调block
 */
- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer completionBlock:(void (^)(NSData *encodedData, NSError *error))completionBlock;

@end
