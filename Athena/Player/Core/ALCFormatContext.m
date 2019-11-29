//
//  SCFormatContext.m
//  Athena
//
//  Created by Theresa on 2018/12/25.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import "ALCFormatContext.h"
#import "ALCTrack.h"
#import "ALCMetaData.h"

@interface ALCFormatContext ()

@property (nonatomic, assign, readwrite) AVFormatContext *core;

@property (nonatomic, assign, readwrite) NSUInteger videoIndex;
@property (nonatomic, assign, readwrite) NSUInteger audioIndex;

@property (nonatomic, assign, readwrite) NSTimeInterval duration;

@property (nonatomic, copy, readwrite) NSArray<ALCTrack *> *tracks;

@end

@implementation ALCFormatContext

- (instancetype)init {
    if (self = [super init]) {
        [self setupDecoder];
    }
    return self;
}

- (void)setupDecoder {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        av_register_all();
        avformat_network_init();
    });
    self.core = avformat_alloc_context();
}

- (BOOL)openPath:(NSString *)path {
    if(avformat_open_input(&self->_core, [path UTF8String], NULL, NULL) != 0){
        NSLog(@"Couldn't open input stream.\n");
        return NO;
    }
    if(avformat_find_stream_info(self.core, NULL) < 0){
        NSLog(@"Couldn't find stream information.\n");
        return NO;
    }
    
    NSMutableArray *allTracks = [NSMutableArray array];
    for (int i = 0; i < self.core->nb_streams; i++) {
        [allTracks addObject:[[ALCTrack alloc] initWithIndex:i
                                                       type:(int)self.core->streams[i]->codecpar->codec_type
                                                       meta:[ALCMetaData metadataWithAVDictionary:self.core->streams[i]->metadata]]];
    }
    __block BOOL videoFound = NO;
    __block BOOL audioFound = NO;
    for (ALCTrack *track in self.tracks) {
        if (!videoFound && track.type == SCTrackTypeVideo) {
            self.videoIndex = track.index;
            videoFound = YES;
        } else if (!audioFound && track.type == SCTrackTypeAudio) {
            self.audioIndex = track.index;
            audioFound = YES;
        }
    }
    self.tracks = allTracks;
    self.duration = self.core->duration / AV_TIME_BASE;
    return YES;
}

- (int)readFrame:(AVPacket *)packet {
    return av_read_frame(self.core, packet);
}

- (void)seekingTime:(NSTimeInterval)time {
    int64_t seek_pos = time * AV_TIME_BASE;
    int64_t seek_target = av_rescale_q(seek_pos, AV_TIME_BASE_Q, self.core->streams[self.videoIndex]->time_base);
    av_seek_frame(self.core, (int)self.videoIndex, seek_target, AVSEEK_FLAG_BACKWARD);
}

- (void)closeFile {
    avformat_close_input(&self->_core);
}

@end
