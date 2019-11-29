//
//  SCTrack.h
//  Athena
//
//  Created by Theresa on 2019/01/29.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(int, SCTrackType) {
    SCTrackTypeUnknown = -1,
    SCTrackTypeVideo,
    SCTrackTypeAudio,
    SCTrackTypeData,
    SCTrackTypeSubtitle,
    SCTrackTypeAttachment,
    SCTrackTypeNB,
};

@class ALCMetaData;

@interface ALCTrack : NSObject

@property (nonatomic, strong, readonly) ALCMetaData *meta;
@property (nonatomic, assign, readonly) int index;
@property (nonatomic, assign, readonly) SCTrackType type;

- (instancetype)initWithIndex:(int)index type:(SCTrackType)type meta:(ALCMetaData *)meta;

@end
