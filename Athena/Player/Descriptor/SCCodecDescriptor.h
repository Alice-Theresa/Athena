//
//  SCCodecDescriptor.h
//  Athena
//
//  Created by Skylar on 2019/10/26.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SCTrack;

@interface SCCodecDescriptor : NSObject

@property (nonatomic, assign) AVRational timebase;
@property (nonatomic, assign) AVCodecParameters *codecpar;
@property (nonatomic, strong) SCTrack *track;

@end

NS_ASSUME_NONNULL_END
