//
//  ALCFlowDataQueue.m
//  Athena
//
//  Created by Skylar on 2019/11/10.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "ALCFlowDataQueue.h"
#import "ALCFlowDataNode.h"

@interface ALCFlowDataQueue ()

@property (nonatomic, assign, readwrite) NSUInteger count;
@property (nonatomic, assign, readwrite) NSUInteger size;

@property (nonatomic, strong) ALCFlowDataNode *header;
@property (nonatomic, strong) ALCFlowDataNode *tailer;

@end

@implementation ALCFlowDataQueue

- (void)enqueue:(NSArray<id<SCFlowData>> *)frames {
    if (frames.count == 0) {
        return;
    }
    for (id<SCFlowData> data in frames) {
        ALCFlowDataNode *node = [[ALCFlowDataNode alloc] initWithData:data];
        if (!self.header) {
            self.header = node;
            self.tailer = node;
        } else {
            self.tailer.next = node;
            self.tailer = node;
        }
        
        self.count++;
    }
}

- (id<SCFlowData>)dequeue {
    if (!self.header) {
        return nil;
    }
    id<SCFlowData> data = self.header.data;
    self.header = self.header.next;
    if (!self.header) {
        self.tailer = nil;
    }
    self.count--;
    return data;
}

- (void)flush {
    self.count = 0;
    self.size = 0;
    self.header = nil;
    self.tailer = nil;
}

@end
