//
//  ALCFlowDataNode.m
//  Athena
//
//  Created by Skylar on 2019/11/10.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "ALCFlowDataNode.h"

@implementation ALCFlowDataNode

- (instancetype)initWithData:(ALCFlowData *)data {
    if (self = [super init]) {
        _data = data;
    }
    return self;
}

@end
