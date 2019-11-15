//
//  SCAudioFrame.h
//  Athena
//
//  Created by Skylar on 2019/11/8.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCFlowData.h"

NS_ASSUME_NONNULL_BEGIN

@class SCAudioDescriptor;

@interface SCAudioFrame : NSObject <SCFrame, SCFlowData>

@property (nonatomic, assign) NSTimeInterval timeStamp;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSUInteger size;
@property (nonatomic, strong) SCCodecDescriptor *codecDescriptor;

@property (nonatomic, assign) int numberOfSamples;

@property (nonatomic, assign) AVFrame *core;
@property (nonatomic, assign) SCFrameType type;

+ (instancetype)audioFrameWithDescriptor:(SCAudioDescriptor *)descriptor numberOfSamples:(int)numberOfSamples;
- (void)createBuffer:(SCAudioDescriptor *)descriptor numberOfSamples:(int)numberOfSamples;
- (uint8_t **)data;
- (void)fillData;

@end

NS_ASSUME_NONNULL_END
