//
//  SCPacket.m
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCPacket.h"

@implementation SCPacket

- (void)dealloc {
    av_packet_unref(_core);
}

- (instancetype)init {
    if (self = [super init]) {
        _core = av_packet_alloc();
    }
    return self;
}

@end
