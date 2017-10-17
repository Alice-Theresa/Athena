//
//  DispatchQueue.h
//  Athena
//
//  Created by Theresa on 2017/10/17.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SharedQueue : NSObject

+ (dispatch_queue_t)audioEncode;
+ (dispatch_queue_t)audioDecode;
+ (dispatch_queue_t)audioCallback;

@end
