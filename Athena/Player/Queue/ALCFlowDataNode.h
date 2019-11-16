//
//  ALCFlowDataNode.h
//  Athena
//
//  Created by Skylar on 2019/11/10.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCFlowData.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALCFlowDataNode : NSObject

@property (nonatomic, strong) SCFlowData *data;
@property (nonatomic, strong) ALCFlowDataNode *next;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithData:(SCFlowData *)data;

@end

NS_ASSUME_NONNULL_END
