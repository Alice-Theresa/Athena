//
//  SCFrameNode.m
//  Athena
//
//  Created by S.C. on 2019/1/27.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCFrameNode.h"

@implementation SCFrameNode

- (instancetype)initWithFrame:(SCFrame *)frame {
    if (self = [super init]) {
        _frame = frame;
    }
    return self;
}

@end
