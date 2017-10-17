//
//  DispatchQueue.m
//  Athena
//
//  Created by Theresa on 2017/10/17.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import "SharedQueue.h"

@implementation SharedQueue

+ (dispatch_queue_t)audioEncode {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.audio.encoder.queue", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

+ (dispatch_queue_t)audioDecode {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.audio.decoder.queue", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

+ (dispatch_queue_t)audioCallback {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.audio.callback.queue", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

@end
