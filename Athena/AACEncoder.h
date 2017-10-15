//
//  AACEncoder.h
//  Athena
//
//  Created by S.C. on 2017/10/15.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AACEncoder : NSObject {
    AudioConverterRef  audioConverter;
    uint8_t           *aacBuffer;
    NSUInteger        aacBufferSize;
    char              *pcmBuffer;
    size_t            pcmBufferSize;
}

@property (nonatomic, strong) dispatch_queue_t encoderQueue;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;

/**
 使用编码器进行AAC编码
 
 @param sampleBuffer 麦克风原始数据
 @param completionBlock 回调block
 */
- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer completionBlock:(void (^)(NSData *encodedData, NSError *error))completionBlock;

@end
