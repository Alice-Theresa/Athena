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

@property (nonatomic, assign) int videoIndex;

- (AVPacket)readFrame;
- (AVCodecContext *)fetchCodecContext;

@end

NS_ASSUME_NONNULL_END
