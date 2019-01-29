//
//  SCTrack.m
//  Athena
//
//  Created by Theresa on 2019/01/29.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCTrack.h"

@implementation SCTrack

- (instancetype)initWithIndex:(int)index type:(SCTrackType)type {
    if (self = [super init]) {
        _index = index;
        _type = type;
    }
    return self;
}

@end
