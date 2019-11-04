//
//  SCAudioDescriptor.h
//  Athena
//
//  Created by Skylar on 2019/11/3.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SCAudioFrame;

@interface SCAudioDescriptor : NSObject

@property (nonatomic, assign) int format;
@property (nonatomic, assign) int numberOfChannels;
@property (nonatomic, assign) int sampleRate;
@property (nonatomic, assign) int64_t channelLayout;

- (instancetype)initWithFrame:(SCAudioFrame *)frame;
- (int)linesize:(int)numberOfSamples;
- (int)numberOfPlanes;

@end

NS_ASSUME_NONNULL_END
