//
//  H264EncoderInterface.h
//  Athena
//
//  Created by Theresa on 2017/10/20.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "H264EncoderDelegate.h"

@protocol H264EncoderInterface <NSObject>

@property (nonatomic, weak) id<H264EncoderDelegate> delegate;
    
/**
 禁用初始化方法
 */
+ (instancetype)new NS_UNAVAILABLE;

/**
 使用编码器进行H264编码
 
 @param imageBuffer 相机原始数据
 */
- (void)encodeSampleBuffer:(CVImageBufferRef)imageBuffer;

/**
 清理编码器
 */
- (void)teardown;

@end
