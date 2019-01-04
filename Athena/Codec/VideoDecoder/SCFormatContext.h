//
//  SCFormatContext.h
//  Athena
//
//  Created by Theresa on 2018/12/25.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avformat.h"

NS_ASSUME_NONNULL_BEGIN

@interface SCFormatContext : NSObject

@property (nonatomic, assign, readonly) int videoIndex;
@property (nonatomic, assign, readonly) NSTimeInterval videoTimebase;

- (AVCodecContext *)fetchCodecContext;
- (int)readFrame:(AVPacket *)packet;

@end

NS_ASSUME_NONNULL_END
