//
//  SCFrame.m
//  Athena
//
//  Created by Theresa on 2019/01/10.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCFrame.h"

@implementation SCFrame

- (instancetype)init {
    if (self = [super init]) {
        _core = av_frame_alloc();
    }
    return self;
}

- (void)dealloc {
    if (self.core) {
        av_frame_free(&self->_core);
    }
}
- (void)fillData {
    
}

@end
