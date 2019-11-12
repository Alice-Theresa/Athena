//
//  SCFrame.h
//  Athena
//
//  Created by Theresa on 2019/01/10.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import <AVFoundation/AVFoundation.h>
#import "SCRenderDataInterface.h"
#import "SCFlowData.h"

typedef NS_ENUM(int, SCFrameType) {
    SCFrameTypeUndefine,
    SCFrameTypeDiscard = 1,
    SCFrameTypeNV12,
    SCFrameTypeI420,
    SCFrameTypeAudio,
};

NS_ASSUME_NONNULL_BEGIN

@class SCCodecDescriptor;

@protocol SCFrame <NSObject>

@property (nonatomic, strong) SCCodecDescriptor *codecDescriptor;
@property (nonatomic, assign) SCFrameType type;
@property (nonatomic, assign) AVFrame *core;

@end

NS_ASSUME_NONNULL_END
