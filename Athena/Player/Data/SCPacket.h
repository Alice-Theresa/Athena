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

@interface SCPacket : NSObject <SCFlowData>

@property (nonatomic, assign) NSTimeInterval timeStamp;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSUInteger size;
@property (nonatomic, strong) SCCodecDescriptor *codecDescriptor;

@property (nonatomic, assign, nullable, readonly) AVPacket *core;

@end

NS_ASSUME_NONNULL_END
