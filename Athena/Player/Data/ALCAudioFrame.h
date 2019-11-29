//
//  SCAudioFrame.h
//  Athena
//
//  Created by Skylar on 2019/11/8.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "ALCFlowData.h"

@class ALCAudioDescriptor;

@interface ALCAudioFrame : ALCFlowData <ALCFrame>

@property (nonatomic, assign) int numberOfSamples;

@property (nonatomic, assign) AVFrame *core;

+ (instancetype)audioFrameWithDescriptor:(ALCAudioDescriptor *)descriptor numberOfSamples:(int)numberOfSamples;
- (uint8_t **)data;
- (void)fillData;

@end
