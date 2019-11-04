//
//  SCAudioFrame.h
//  Athena
//
//  Created by Theresa on 2019/01/09.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCFrame.h"

@interface SCAudioFrame : SCFrame

@property (nonatomic, assign) int numberOfSamples;
@property (nonatomic, assign, nullable) AVFrame *core;

- (uint8_t **)data;
- (void)fillData;

@end
