//
//  SCFlowData.h
//  Athena
//
//  Created by Skylar on 2019/10/31.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>

typedef NS_ENUM(int, SCFlowDataType) {
    SCFlowDataTypeUndefine = 0,
    SCFlowDataTypePacket,
    SCFlowDataTypeFrame,
    SCFlowDataTypeDiscard,
};

typedef NS_ENUM(int, SCMediaType) {
    SCMediaTypeUndefine = 0,
    SCMediaTypeVideo,
    SCMediaTypeAudio,
};

typedef NS_ENUM(int, SCVideoFrameFormat) {
    SCVideoFrameFormatUndefine = 0,
    SCVideoFrameFormatNV12,
    SCVideoFrameFormatI420,
};

@protocol SCFrame <NSObject>

@property (nonatomic, assign) AVFrame *core;

- (uint8_t **)data;
- (void)fillData;

@end

@class SCCodecDescriptor;

@interface SCFlowData : NSObject

@property (nonatomic, assign) NSTimeInterval    timeStamp;
@property (nonatomic, assign) NSTimeInterval    duration;
@property (nonatomic, assign) NSUInteger        size;
@property (nonatomic, assign) SCFlowDataType    flowDataType;
@property (nonatomic, assign) SCMediaType       mediaType;
@property (nonatomic, strong) SCCodecDescriptor *codecDescriptor;

@end
