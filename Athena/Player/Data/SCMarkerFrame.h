//
//  SCMarkerFrame.h
//  Athena
//
//  Created by Skylar on 2019/11/8.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface SCMarkerFrame : NSObject <SCFlowData>

@property (nonatomic, assign) SCFrameType type;

@property (nonatomic, assign) NSTimeInterval timeStamp;
@property (nonatomic, assign) NSTimeInterval duration;

@end

NS_ASSUME_NONNULL_END
