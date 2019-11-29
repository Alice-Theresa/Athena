//
//  SCDecoder.h
//  Athena
//
//  Created by Skylar on 2019/11/16.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALCFlowData.h"

NS_ASSUME_NONNULL_BEGIN

@class ALCPacket;

@protocol ALCDecoder <NSObject>

- (NSArray<id<ALCFrame>> *)decode:(ALCPacket *)packet;
- (void)flush;

@end

NS_ASSUME_NONNULL_END
