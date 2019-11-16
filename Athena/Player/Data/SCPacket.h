//
//  SCPacket.h
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>
#import "SCFlowData.h"

NS_ASSUME_NONNULL_BEGIN

@class SCCodecDescriptor;

@interface SCPacket : SCFlowData

@property (nonatomic, assign, nullable, readonly) AVPacket *core;

@end

NS_ASSUME_NONNULL_END
