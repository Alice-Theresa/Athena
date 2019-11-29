//
//  SCAudioDecoder.h
//  Athena
//
//  Created by Theresa on 2019/01/09.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALCDecoder.h"

@class ALCPacket;
@class ALCFormatContext;

NS_ASSUME_NONNULL_BEGIN

@interface ALCAudioDecoder : NSObject <ALCDecoder>

- (NSArray<id<ALCFrame>> *)decode:(ALCPacket *)packet;
- (void)flush;

@end

NS_ASSUME_NONNULL_END
