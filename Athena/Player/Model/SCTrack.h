//
//  SCTrack.h
//  Athena
//
//  Created by Theresa on 2019/01/29.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(int, SCTrackType) {
    SCTrackTypeVideo = 0,
    SCTrackTypeAudio = 1,
    SCTrackTypeSubtitle = 2,
};

@class SCMetaData;

NS_ASSUME_NONNULL_BEGIN

@interface SCTrack : NSObject

@property (nonatomic, strong, readonly) SCMetaData *meta;
@property (nonatomic, assign, readonly) int index;
@property (nonatomic, assign, readonly) SCTrackType type;

- (instancetype)initWithIndex:(int)index type:(SCTrackType)type meta:(SCMetaData *)meta;

@end

NS_ASSUME_NONNULL_END
