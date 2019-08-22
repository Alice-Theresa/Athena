//
//  VideoDecoder.h
//  Athena
//
//  Created by Theresa on 2018/12/24.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import "SCDecoderInterface.h"
#import "Athena-Swift.h"

@class SCFrame;
@class SCFormatContext;

NS_ASSUME_NONNULL_BEGIN

@interface SCVTDecoder : NSObject //<VideoDecoder>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFormatContext:(SCFormatContext *)formatContext;
- (NSArray<SCFrame *> *)decodeWithPacket:(AVPacket)packet;

@end

NS_ASSUME_NONNULL_END
