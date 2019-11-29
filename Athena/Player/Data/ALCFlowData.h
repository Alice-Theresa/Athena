//
//  SCFlowData.h
//  Athena
//
//  Created by Skylar on 2019/10/31.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>

typedef NS_ENUM(int, ALCFlowDataType) {
    ALCFlowDataTypeUndefine = 0,
    ALCFlowDataTypePacket,
    ALCFlowDataTypeFrame,
    ALCFlowDataTypeDiscard,
};

typedef NS_ENUM(int, ALCMediaType) {
    ALCMediaTypeUndefine = 0,
    ALCMediaTypeVideo,
    ALCMediaTypeAudio,
};

typedef NS_ENUM(int, ALCVideoFrameFormat) {
    ALCVideoFrameFormatUndefine = 0,
    ALCVideoFrameFormatNV12,
    ALCVideoFrameFormatI420,
};

@protocol ALCFrame <NSObject>

@property (nonatomic, assign) AVFrame *core;

- (uint8_t **)data;
- (void)fillData;

@end

@class ALCCodecDescriptor;

@interface ALCFlowData : NSObject

@property (nonatomic, assign) NSTimeInterval    timeStamp;
@property (nonatomic, assign) NSTimeInterval    duration;
@property (nonatomic, assign) NSUInteger        size;
@property (nonatomic, assign) ALCFlowDataType    flowDataType;
@property (nonatomic, assign) ALCMediaType       mediaType;
@property (nonatomic, strong) ALCCodecDescriptor *codecDescriptor;

@end
