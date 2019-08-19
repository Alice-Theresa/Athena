//
//  SCPacketNode.m
//  Athena
//
//  Created by Theresa on 2019/01/29.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCPacketNode.h"

@implementation SCPacketNode

- (instancetype)initWithPacket:(NSValue *)packet {
    if (self = [super init]) {
        _packet = packet;
    }
    return self;
}

@end
