//
//  SCAudioDecoder.h
//  Athena
//
//  Created by Theresa on 2019/01/09.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCFormatContext;

NS_ASSUME_NONNULL_BEGIN

@interface SCAudioDecoder : NSObject

- (instancetype)initWithFormatContext:(SCFormatContext *)formatContext;
- (void)synchronizedDecode:(AVPacket)packet;

@end

NS_ASSUME_NONNULL_END
