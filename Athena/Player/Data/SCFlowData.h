//
//  SCFlowData.h
//  Athena
//
//  Created by Skylar on 2019/10/31.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>

typedef NS_ENUM(int, SCFrameType) {
    SCFrameTypeUndefine,
    SCFrameTypeDiscard = 1,
    SCFrameTypeNV12,
    SCFrameTypeI420,
    SCFrameTypeAudio,
};

@class SCCodecDescriptor;

@protocol SCFlowData <NSObject>

@property (nonatomic, assign) NSTimeInterval timeStamp;
@property (nonatomic, assign) NSTimeInterval duration;

@end

@protocol SCFrame <NSObject>

@property (nonatomic, strong) SCCodecDescriptor *codecDescriptor;
@property (nonatomic, assign) SCFrameType type;
@property (nonatomic, assign) AVFrame *core;

@end
