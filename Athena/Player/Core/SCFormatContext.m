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

@interface SCFormatContext () {
    AVFormatContext *formatContext;
    AVCodec *videoCodec;
    AVCodec *audioCodec;
}

@property (nonatomic, assign, readwrite) int videoIndex;
@property (nonatomic, assign, readwrite) int audioIndex;
@property (nonatomic, assign, readwrite) int subtitleIndex;

@property (nonatomic, assign, readwrite) NSTimeInterval videoTimebase;
@property (nonatomic, assign, readwrite) NSTimeInterval audioTimebase;
@property (nonatomic, assign, readwrite) NSTimeInterval duration;

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
    formatContext = avformat_alloc_context();
}

- (void)openPath:(NSString *)path {
    if(avformat_open_input(&formatContext, [path UTF8String], NULL, NULL) != 0){
        printf("Couldn't open input stream.\n");
        return ;
    }
    if(avformat_find_stream_info(formatContext, NULL) < 0){
        printf("Couldn't find stream information.\n");
        return;
    }
    
    NSMutableArray *videoTracks = [NSMutableArray array];
    NSMutableArray *audioTracks = [NSMutableArray array];
    NSMutableArray *subtitleTracks = [NSMutableArray array];
    for (int i = 0; i < formatContext->nb_streams; i++) {
        switch (formatContext->streams[i]->codecpar->codec_type) {
            case AVMEDIA_TYPE_VIDEO:
                [videoTracks addObject:[[SCTrack alloc] initWithIndex:i
                                                                 type:SCTrackTypeVideo
                                                                 meta:[SCMetaData metadataWithAVDictionary:formatContext->streams[i]->metadata]]];
                break;
            case AVMEDIA_TYPE_AUDIO:
                [audioTracks addObject:[[SCTrack alloc] initWithIndex:i
                                                                 type:SCTrackTypeAudio
                                                                 meta:[SCMetaData metadataWithAVDictionary:formatContext->streams[i]->metadata]]];
                break;
            case AVMEDIA_TYPE_SUBTITLE:
                [subtitleTracks addObject:[[SCTrack alloc] initWithIndex:i
                                                                    type:SCTrackTypeSubtitle
                                                                    meta:[SCMetaData metadataWithAVDictionary:formatContext->streams[i]->metadata]]];
                break;
            default:
                break;
        }
    }
    self.videoTracks = videoTracks;
    self.audioTracks = audioTracks;
    self.subtitleTracks = subtitleTracks;
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
    
    AVStream *videoStream = formatContext->streams[self.videoIndex];
    AVStream *audioStream = formatContext->streams[self.audioIndex];
    videoCodec =  avcodec_find_decoder(videoStream->codecpar->codec_id);
    audioCodec =  avcodec_find_decoder(audioStream->codecpar->codec_id);
    _videoCodecContext = avcodec_alloc_context3(videoCodec);
    _audioCodecContext = avcodec_alloc_context3(audioCodec);
    avcodec_parameters_to_context(_videoCodecContext, videoStream->codecpar);
    avcodec_parameters_to_context(_audioCodecContext, audioStream->codecpar);
//    av_codec_set_pkt_timebase(codec_ctx, stream->time_base);
    if(audioCodec == NULL || videoCodec == NULL) {
        printf("Couldn't find Codec.\n");
        return;
    }
    if(avcodec_open2(self.audioCodecContext, audioCodec, NULL) < 0 || avcodec_open2(self.videoCodecContext, videoCodec, NULL) < 0) {
        printf("Couldn't open codec.\n");
        return;
    }
    
    [self settingTimeBase];
    [self settingDuration];
}

- (void)closeFile {
    avcodec_close(_videoCodecContext);
    avcodec_close(_audioCodecContext);
    avformat_close_input(&formatContext);
}

- (int)readFrame:(AVPacket *)packet {
    return av_read_frame(formatContext, packet);
}

- (void)seekingTime:(NSTimeInterval)time {
    int64_t seek_pos = time * AV_TIME_BASE;
    int64_t seek_target = av_rescale_q(seek_pos, AV_TIME_BASE_Q, formatContext->streams[self.videoIndex]->time_base);
    av_seek_frame(formatContext, self.videoIndex, seek_target, AVSEEK_FLAG_BACKWARD);
}

- (void)settingTimeBase {
    AVStream *stream = formatContext->streams[self.videoIndex];
    if (stream->time_base.den > 0 && stream->time_base.num > 0) {
        self.videoTimebase = av_q2d(stream->time_base);
    } else {
        NSAssert(NO, @"no time base");
    }
    
    AVStream *audioStream = formatContext->streams[self.audioIndex];
    if (audioStream->time_base.den > 0 && audioStream->time_base.num > 0) {
        self.audioTimebase = av_q2d(audioStream->time_base);
    } else {
        NSAssert(NO, @"no time base");
    }
}

- (void)settingDuration {
    self.duration = formatContext->duration / AV_TIME_BASE;
}

@end
