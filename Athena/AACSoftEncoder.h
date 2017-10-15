//
//  AACSoftEncoder.h
//  Athena
//
//  Created by S.C. on 2017/10/15.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import "AACEncoder.h"

@interface AACSoftEncoder : AACEncoder

/**
 使用编码器进行AAC编码
 
 @param sampleBuffer 麦克风原始数据
 @param completionBlock 回调block
 */
- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer completionBlock:(void (^)(NSData *encodedData, NSError *error))completionBlock;

@end
