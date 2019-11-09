//
//  SCMarkerFrame.m
//  Athena
//
//  Created by Skylar on 2019/11/8.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCMarkerFrame.h"

@implementation SCMarkerFrame

@synthesize type = _type;

- (instancetype)init {
    if (self = [super init]) {
        _type = SCFrameTypeDiscard;
    }
    return self;
}

@end
