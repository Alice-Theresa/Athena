//
//  SCFormatContext.h
//  Athena
//
//  Created by Theresa on 2018/12/25.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>

@class SCTrack;

NS_ASSUME_NONNULL_BEGIN

@interface ALCFormatContext : NSObject

@property (nonatomic, assign, readonly) AVFormatContext *core;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, copy, readonly) NSArray<SCTrack *> *tracks;

- (BOOL)openPath:(NSString *)path;
- (int)readFrame:(AVPacket *)packet;
- (void)seekingTime:(NSTimeInterval)time;
- (void)closeFile;

@end

NS_ASSUME_NONNULL_END
