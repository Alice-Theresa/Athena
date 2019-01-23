//
//  SCDecoderInterface.h
//  Athena
//
//  Created by Theresa on 2019/01/23.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import <Foundation/Foundation.h>

@class SCFrame;
@class SCFormatContext;

NS_ASSUME_NONNULL_BEGIN

@protocol SCDecoderInterface <NSObject>

@property (nonatomic, weak, readonly) SCFormatContext *context;

- (instancetype)initWithFormatContext:(SCFormatContext *)formatContext;
- (NSArray<SCFrame *> *)decode:(AVPacket)packet;

@end

NS_ASSUME_NONNULL_END
