//
//  SCCodecContext.h
//  Athena
//
//  Created by Skylar on 2019/10/26.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCCodecContext : NSObject

@property (nonatomic, assign) AVCodecContext *core;

- (instancetype)initWithTimebase:(AVRational)timebase codecpar:(AVCodecParameters *)codecpar;
- (void)close;
- (void)flush;

@end

NS_ASSUME_NONNULL_END
