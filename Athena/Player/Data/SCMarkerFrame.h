//
//  SCMarkerFrame.h
//  Athena
//
//  Created by Skylar on 2019/11/8.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCFlowData.h"

NS_ASSUME_NONNULL_BEGIN

@interface SCMarkerFrame : NSObject <SCFrame>

@property (nonatomic, assign) NSTimeInterval timeStamp;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSUInteger size;
@property (nonatomic, assign) SCFlowDataType flowDataType;
@property (nonatomic, assign) SCMediaType type;
@property (nonatomic, strong) SCCodecDescriptor *codecDescriptor;

@property (nonatomic, assign) AVFrame *core;

@end

NS_ASSUME_NONNULL_END
