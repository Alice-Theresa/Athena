//
//  H264EncoderDelegate.h
//  Athena
//
//  Created by Theresa on 2017/10/20.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol H264EncoderDelegate <NSObject>

/**
 编码完成数据回调
 
 @param data 编码数据
 @param error 编码错误
 */
- (void)encodedResult:(NSData *)data error:(NSError *)error;

@end
