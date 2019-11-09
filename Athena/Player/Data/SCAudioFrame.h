//
//  SCAudioFrame.h
//  Athena
//
//  Created by Skylar on 2019/11/8.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCFrame.h"

NS_ASSUME_NONNULL_BEGIN

@class SCAudioDescriptor;

@interface SCAudioFrame : SCFrame

@property (nonatomic, assign) int numberOfSamples;

- (void)createBuffer:(SCAudioDescriptor *)descriptor numberOfSamples:(int)numberOfSamples;
- (uint8_t **)data;
- (void)fillData;

@end

NS_ASSUME_NONNULL_END
