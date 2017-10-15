//
//  AACEncoder.h
//  Athena
//
//  Created by Theresa on 2017/9/30.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import "AACEncoder.h"

@interface AACHardEncoder : AACEncoder

/**
 使用编码器进行AAC编码

 @param sampleBuffer 麦克风原始数据
 @param completionBlock 回调block
 */
- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer completionBlock:(void (^)(NSData *encodedData, NSError *error))completionBlock;

@end
