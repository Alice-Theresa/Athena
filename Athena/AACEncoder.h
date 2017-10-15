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

@end
