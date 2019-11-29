//
//  SCPacket.m
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "ALCPacket.h"

@implementation ALCPacket

- (void)dealloc {
    av_packet_unref(_core);
    av_packet_free(&_core);
    _core = nil;
}

- (instancetype)init {
    if (self = [super init]) {
        _core = av_packet_alloc();  
    }
    return self;
}

@end
