//
//  SCVideoDecoder.h
//  Athena
//
//  Created by Theresa on 2019/01/07.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCDecoderInterface.h"

@class SCFrame;
@class SCFormatContext;

NS_ASSUME_NONNULL_BEGIN

@interface SCVideoDecoder : NSObject <SCDecoderInterface>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFormatContext:(SCFormatContext *)formatContext;
- (NSArray<SCFrame *> *)decode:(AVPacket)packet;

@end

NS_ASSUME_NONNULL_END
