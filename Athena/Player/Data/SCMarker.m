//
//  SCMarker.m
//  Athena
//
//  Created by Skylar on 2019/11/8.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCMarker.h"

@implementation SCMarker

@synthesize flowDataType = _flowDataType;

- (instancetype)init {
    if (self = [super init]) {
        _flowDataType = SCFlowDataTypeDiscard;
    }
    return self;
}

@end
