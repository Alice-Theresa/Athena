//
//  H264HardwareEncoder.h
//  Athena
//
//  Created by Theresa on 2017/10/20.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "H264EncoderInterface.h"
#import "H264EncoderDelegate.h"

@interface H264HardwareEncoder : NSObject <H264EncoderInterface>

@property (nonatomic, weak) id<H264EncoderDelegate> delegate;

/**
 移除编码器
 */
- (void)removeEncodeSession;

/**
 使用编码器进行H264编码

 @param sampleBuffer 相机原始数据
 */
- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
