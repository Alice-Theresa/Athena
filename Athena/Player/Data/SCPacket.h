//
//  SCPacket.h
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>

NS_ASSUME_NONNULL_BEGIN

@class SCCodecDescriptor;

@interface SCPacket : NSObject

@property (nonatomic, assign) AVPacket *core;
@property (nonatomic, strong) SCCodecDescriptor *codecDescriptor;

@end

NS_ASSUME_NONNULL_END
