//
//  SCFormatContext.h
//  Athena
//
//  Created by Theresa on 2018/12/25.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>

@class Track;
//@class SCTrack;
@class YuuPacket;

NS_ASSUME_NONNULL_BEGIN

@interface SCFormatContext : NSObject

@property (nonatomic, assign, readonly) int videoIndex;
@property (nonatomic, assign, readonly) int audioIndex;
@property (nonatomic, assign, readonly) int subtitleIndex;

@property (nonatomic, assign, readonly) NSTimeInterval videoTimebase;
@property (nonatomic, assign, readonly) NSTimeInterval audioTimebase;

@property (nonatomic, assign, readonly) NSTimeInterval duration;    //unit: second

@property (nonatomic, assign) AVCodecContext *videoCodecContext;
@property (nonatomic, assign) AVCodecContext *audioCodecContext;

@property (nonatomic, strong, readonly) NSArray<Track *> *videoTracks;
@property (nonatomic, strong, readonly) NSArray<Track *> *audioTracks;
@property (nonatomic, strong, readonly) NSArray<Track *> *subtitleTracks;

- (int)readFrame:(YuuPacket *)packet;
- (void)seekingTime:(NSTimeInterval)time;

- (void)openPath:(NSString *)path;
- (void)closeFile;

@end

NS_ASSUME_NONNULL_END
