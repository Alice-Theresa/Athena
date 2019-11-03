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

@interface SCCodecDescriptor : NSObject

@property (nonatomic, assign) AVRational timebase;
@property (nonatomic, assign) AVCodecParameters *codecpar;

@end

NS_ASSUME_NONNULL_END
