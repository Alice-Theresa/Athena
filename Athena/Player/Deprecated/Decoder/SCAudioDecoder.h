//
//  SCAudioDecoder.h
//  Athena
//
//  Created by Theresa on 2019/01/09.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCDecoderInterface.h"
@class SCFrame;
@class SCFormatContext;

NS_ASSUME_NONNULL_BEGIN

@interface SCAudioDecoder : NSObject <SCDecoderInterface>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFormatContext:(SCFormatContext *)formatContext;
- (NSArray<SCFrame *> *)decode:(AVPacket)packet;

@end

NS_ASSUME_NONNULL_END
