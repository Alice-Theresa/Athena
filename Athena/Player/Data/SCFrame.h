//
//  SCFrame.h
//  Athena
//
//  Created by Theresa on 2019/01/10.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(int, SCFrameType) {
    SCFrameTypeDiscard = 1,
    SCFrameTypeNV12,
    SCFrameTypeI420,
};

NS_ASSUME_NONNULL_BEGIN

@interface SCFrame : NSObject

@property (nonatomic, assign) AVFrame *core;

@property (nonatomic, assign) SCFrameType type;

@property (nonatomic, assign) NSTimeInterval position;
@property (nonatomic, assign) NSTimeInterval duration;

@end

NS_ASSUME_NONNULL_END
