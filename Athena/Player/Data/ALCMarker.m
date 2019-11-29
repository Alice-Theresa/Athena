//
//  SCMarker.m
//  Athena
//
//  Created by Skylar on 2019/11/8.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "ALCMarker.h"

@implementation ALCMarker

@synthesize flowDataType = _flowDataType;

- (instancetype)init {
    if (self = [super init]) {
        _flowDataType = ALCFlowDataTypeDiscard;
    }
    return self;
}

@end
