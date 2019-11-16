//
//  SCDecoder.h
//  Athena
//
//  Created by Skylar on 2019/11/16.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCFlowData.h"

NS_ASSUME_NONNULL_BEGIN

@class SCPacket;

@protocol SCDecoder <NSObject>

- (NSArray<id<SCFrame>> *)decode:(SCPacket *)packet;
- (void)flush;

@end

NS_ASSUME_NONNULL_END
