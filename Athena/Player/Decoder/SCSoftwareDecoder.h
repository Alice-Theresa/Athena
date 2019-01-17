//
//  SCSoftwareDecoder.h
//  Athena
//
//  Created by Theresa on 2019/01/07.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCFrame;
@class SCFormatContext;

NS_ASSUME_NONNULL_BEGIN

@interface SCSoftwareDecoder : NSObject

- (instancetype)initWithFormatContext:(SCFormatContext *)formatContext;
- (SCFrame *)decode;

@end

NS_ASSUME_NONNULL_END
