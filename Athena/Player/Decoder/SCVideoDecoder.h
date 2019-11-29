//
//  SCVideoDecoder.h
//  Athena
//
//  Created by Theresa on 2019/01/07.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCDecoder.h"

@class ALCFormatContext;

NS_ASSUME_NONNULL_BEGIN

@interface SCVideoDecoder : NSObject <SCDecoder>

- (NSArray<id<SCFrame>> *)decode:(SCPacket *)packet;
- (void)flush;

@end

NS_ASSUME_NONNULL_END
