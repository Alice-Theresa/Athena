//
//  VideoDecoder.h
//  Athena
//
//  Created by Theresa on 2018/12/24.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import "SCDecoderInterface.h"

@class SCFrame;
@class SCFormatContext;

NS_ASSUME_NONNULL_BEGIN

@interface SCVTDecoder : NSObject <SCDecoderInterface>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFormatContext:(SCFormatContext *)formatContext;
- (NSArray<SCFrame *> *)decode:(AVPacket)packet;

@end

NS_ASSUME_NONNULL_END
