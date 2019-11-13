//
//  SCMarkerFrame.h
//  Athena
//
//  Created by Skylar on 2019/11/8.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCFlowData.h"

NS_ASSUME_NONNULL_BEGIN

@interface SCMarkerFrame : NSObject <SCFrame, SCFlowData>

@property (nonatomic, strong) SCCodecDescriptor *codecDescriptor;
@property (nonatomic, assign) SCFrameType type;

@end

NS_ASSUME_NONNULL_END
