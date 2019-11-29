//
//  SCAudioFrame.h
//  Athena
//
//  Created by Skylar on 2019/11/8.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCFlowData.h"

@class ALCAudioDescriptor;

@interface SCAudioFrame : SCFlowData <SCFrame>

@property (nonatomic, assign) int numberOfSamples;

@property (nonatomic, assign) AVFrame *core;

+ (instancetype)audioFrameWithDescriptor:(ALCAudioDescriptor *)descriptor numberOfSamples:(int)numberOfSamples;
- (uint8_t **)data;
- (void)fillData;

@end
