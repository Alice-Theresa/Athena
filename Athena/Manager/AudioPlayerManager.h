//
//  AudioPlayerManager.h
//  Athena
//
//  Created by Theresa on 2018/9/28.
//  Copyright © 2018年 Theresa. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface AudioPlayerManager : NSObject

+ (instancetype)shared;

- (void)settingMode;

@end
