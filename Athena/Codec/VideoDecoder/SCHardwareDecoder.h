//
//  VideoDecoder.h
//  Athena
//
//  Created by Theresa on 2018/12/24.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCVideoFrame;
@class SCFormatContext;

NS_ASSUME_NONNULL_BEGIN

@interface SCHardwareDecoder : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFormatContext:(SCFormatContext *)formatContext;
- (SCVideoFrame *)decode;

@end

NS_ASSUME_NONNULL_END
