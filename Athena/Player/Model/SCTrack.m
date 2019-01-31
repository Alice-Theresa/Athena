//
//  SCTrack.m
//  Athena
//
//  Created by Theresa on 2019/01/29.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCTrack.h"

@implementation SCTrack

- (instancetype)initWithIndex:(int)index type:(SCTrackType)type meta:(SCMetaData *)meta {
    if (self = [super init]) {
        _index = index;
        _type = type;
        _meta = meta;
    }
    return self;
}

@end
