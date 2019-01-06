//
//  SCDemuxer.h
//  Athena
//
//  Created by Theresa on 2018/12/29.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCFormatContext;

NS_ASSUME_NONNULL_BEGIN

@interface SCDemuxer : NSObject

- (instancetype)init;


- (void)open;

- (void)pause;
- (void)resume;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
