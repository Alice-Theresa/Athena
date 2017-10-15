//
//  AACEncoder.m
//  Athena
//
//  Created by S.C. on 2017/10/15.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import "AACEncoder.h"

@implementation AACEncoder

- (instancetype)init {
    if (self = [super init]) {
        _encoderQueue  = dispatch_queue_create("com.encoder.queue", DISPATCH_QUEUE_SERIAL);
        _callbackQueue = dispatch_queue_create("com.callback.queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

@end
