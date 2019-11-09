//
//  SCAudioDecoder.h
//  Athena
//
//  Created by Theresa on 2019/01/09.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCFrame;
@class SCPacket;
@class SCFormatContext;

NS_ASSUME_NONNULL_BEGIN

@interface SCAudioDecoder : NSObject 

- (NSArray<SCFrame *> *)decode:(SCPacket *)packet;
- (void)flush;

@end

NS_ASSUME_NONNULL_END
