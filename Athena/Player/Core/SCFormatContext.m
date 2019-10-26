//
//  SCFormatContext.m
//  Athena
//
//  Created by Theresa on 2018/12/25.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import "SCFormatContext.h"
#import "SCTrack.h"
#import "SCMetaData.h"

@interface SCFormatContext ()

@property (nonatomic, assign, readwrite) AVFormatContext *formatContext;

@property (nonatomic, assign, readwrite) int videoIndex;
@property (nonatomic, assign, readwrite) int audioIndex;
@property (nonatomic, assign, readwrite) int subtitleIndex;

@property (nonatomic, assign, readwrite) NSTimeInterval videoTimebase;
@property (nonatomic, assign, readwrite) NSTimeInterval audioTimebase;
@property (nonatomic, assign, readwrite) NSTimeInterval duration;

@property (nonatomic, strong, readwrite) NSArray<SCTrack *> *tracks;
@property (nonatomic, strong, readwrite) NSArray<SCTrack *> *videoTracks;
@property (nonatomic, strong, readwrite) NSArray<SCTrack *> *audioTracks;
@property (nonatomic, strong, readwrite) NSArray<SCTrack *> *subtitleTracks;

@end

@implementation SCFormatContext

- (instancetype)init {
    if (self = [super init]) {
        _videoIndex = -1;
        _audioIndex = -1;
        _subtitleIndex = -1;
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
    self.formatContext = avformat_alloc_context();
}

- (void)openPath:(NSString *)path {
    if(avformat_open_input(&self->_formatContext, [path UTF8String], NULL, NULL) != 0){
        printf("Couldn't open input stream.\n");
        return ;
    }
    if(avformat_find_stream_info(self.formatContext, NULL) < 0){
        printf("Couldn't find stream information.\n");
        return;
    }
    
    NSMutableArray *videoTracks = [NSMutableArray array];
    NSMutableArray *audioTracks = [NSMutableArray array];
    NSMutableArray *subtitleTracks = [NSMutableArray array];
    for (int i = 0; i < self.formatContext->nb_streams; i++) {
        switch (self.formatContext->streams[i]->codecpar->codec_type) {
            case AVMEDIA_TYPE_VIDEO:
                [videoTracks addObject:[[SCTrack alloc] initWithIndex:i
                                                                 type:SCTrackTypeVideo
                                                                 meta:[SCMetaData metadataWithAVDictionary:self.formatContext->streams[i]->metadata]]];
                break;
            case AVMEDIA_TYPE_AUDIO:
                [audioTracks addObject:[[SCTrack alloc] initWithIndex:i
                                                                 type:SCTrackTypeAudio
                                                                 meta:[SCMetaData metadataWithAVDictionary:self.formatContext->streams[i]->metadata]]];
                break;
            case AVMEDIA_TYPE_SUBTITLE:
                [subtitleTracks addObject:[[SCTrack alloc] initWithIndex:i
                                                                    type:SCTrackTypeSubtitle
                                                                    meta:[SCMetaData metadataWithAVDictionary:self.formatContext->streams[i]->metadata]]];
                break;
            default:
                break;
        }
    }
    self.videoTracks = videoTracks;
    self.audioTracks = audioTracks;
    self.subtitleTracks = subtitleTracks;
    self.tracks = @[videoTracks, audioTracks];
    if (self.videoTracks.count <= 0) {
        printf("Couldn't find a video stream.\n");
    } else if (self.audioTracks.count <= 0) {
        printf("Couldn't find a audio stream.\n");
    } else if (self.subtitleTracks.count <= 0) {
        printf("Couldn't find a subtitle stream.\n");
    }
    self.videoIndex = self.videoTracks.firstObject.index;
    self.audioIndex = self.audioTracks.firstObject.index;
    self.subtitleIndex = self.subtitleTracks.firstObject.index;
    [self settingTimeBase];
    [self settingDuration];
}

- (void)closeFile {
    avformat_close_input(&self->_formatContext);
}

- (int)readFrame:(AVPacket *)packet {
    return av_read_frame(self.formatContext, packet);
}

- (void)seekingTime:(NSTimeInterval)time {
    int64_t seek_pos = time * AV_TIME_BASE;
    int64_t seek_target = av_rescale_q(seek_pos, AV_TIME_BASE_Q, self.formatContext->streams[self.videoIndex]->time_base);
    av_seek_frame(self.formatContext, self.videoIndex, seek_target, AVSEEK_FLAG_BACKWARD);
}

- (void)settingTimeBase {
    AVStream *stream = self.formatContext->streams[self.videoIndex];
    if (stream->time_base.den > 0 && stream->time_base.num > 0) {
        self.videoTimebase = av_q2d(stream->time_base);
    } else {
        NSAssert(NO, @"no time base");
    }
    
    AVStream *audioStream = self.formatContext->streams[self.audioIndex];
    if (audioStream->time_base.den > 0 && audioStream->time_base.num > 0) {
        self.audioTimebase = av_q2d(audioStream->time_base);
    } else {
        NSAssert(NO, @"no time base");
    }
}

- (void)settingDuration {
    self.duration = self.formatContext->duration / AV_TIME_BASE;
}

@end
