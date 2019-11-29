//
//  SCTrack.m
//  Athena
//
//  Created by Theresa on 2019/01/29.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "ALCTrack.h"

@implementation ALCTrack

- (instancetype)initWithIndex:(int)index type:(SCTrackType)type meta:(ALCMetaData *)meta {
    if (self = [super init]) {
        _index = index;
        _type = type;
        _meta = meta;
    }
    return self;
}

@end
