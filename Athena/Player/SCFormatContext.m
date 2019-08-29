//
//  SCFormatContext.m
//  Athena
//
//  Created by Theresa on 2018/12/25.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import "SCFormatContext.h"
#import "Athena-Swift.h"

@interface SCFormatContext () {
    AVFormatContext *formatContext;
//    YuuFormatContext *formatContext;
    AVCodec *videoCodec;
    AVCodec *audioCodec;
}

@property (nonatomic, assign, readwrite) int videoIndex;
@property (nonatomic, assign, readwrite) int audioIndex;
@property (nonatomic, assign, readwrite) int subtitleIndex;

@property (nonatomic, assign, readwrite) NSTimeInterval videoTimebase;
@property (nonatomic, assign, readwrite) NSTimeInterval audioTimebase;
@property (nonatomic, assign, readwrite) NSTimeInterval duration;

@property (nonatomic, strong, readwrite) NSArray<Track *> *videoTracks;
@property (nonatomic, strong, readwrite) NSArray<Track *> *audioTracks;
@property (nonatomic, strong, readwrite) NSArray<Track *> *subtitleTracks;

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
//    formatContext = [[YuuFormatContext alloc] init];// avformat_alloc_context();
}

- (void)openPath:(NSString *)path {
//    AVFormatContext *p = formatContext.cContextPtr;
//    if(avformat_open_input(&p, [path UTF8String], NULL, NULL) != 0){
//        printf("Couldn't open input stream.\n");
//        return ;
//    }
//    if(avformat_find_stream_info(p, NULL) < 0){
//        printf("Couldn't find stream information.\n");
//        return;
//    }
//
//    NSMutableArray *videoTracks = [NSMutableArray array];
//    NSMutableArray *audioTracks = [NSMutableArray array];
//    NSMutableArray *subtitleTracks = [NSMutableArray array];
//    for (int i = 0; i < formatContext.streamCount; i++) {
//        switch (formatContext.streams[i].codecParameters.mediaType) {
//            case AVMEDIA_TYPE_VIDEO:
//                [videoTracks addObject:[[Track alloc] initWithType:TrackTypeVideo index:i metadata:formatContext.streams[i].metadata]];
//                break;
//            case AVMEDIA_TYPE_AUDIO:
//                [audioTracks addObject:[[Track alloc] initWithType:TrackTypeAudio index:i metadata:formatContext.streams[i].metadata]];
//                break;
//            case AVMEDIA_TYPE_SUBTITLE:
//                [subtitleTracks addObject:[[Track alloc] initWithType:TrackTypeSubtitle index:i metadata:formatContext.streams[i].metadata]];
//                break;
//            default:
//                break;
//        }
//    }
//    self.videoTracks = videoTracks;
//    self.audioTracks = audioTracks;
//    self.subtitleTracks = subtitleTracks;
//    if (self.videoTracks.count <= 0) {
//        printf("Couldn't find a video stream.\n");
//    } else if (self.audioTracks.count <= 0) {
//        printf("Couldn't find a audio stream.\n");
//    } else if (self.subtitleTracks.count <= 0) {
//        printf("Couldn't find a subtitle stream.\n");
//    }
//    self.videoIndex = self.videoTracks.firstObject.index;
//    self.audioIndex = self.audioTracks.firstObject.index;
//    self.subtitleIndex = self.subtitleTracks.firstObject.index;
//    
//    AVStream *videoStream = formatContext.cContextPtr->streams[self.videoIndex];
//    AVStream *audioStream = formatContext.cContextPtr->streams[self.audioIndex];
//    videoCodec =  avcodec_find_decoder(videoStream->codecpar->codec_id);
//    audioCodec =  avcodec_find_decoder(audioStream->codecpar->codec_id);
//    _videoCodecContext = avcodec_alloc_context3(videoCodec);
//    _audioCodecContext = avcodec_alloc_context3(audioCodec);
//    avcodec_parameters_to_context(_videoCodecContext, videoStream->codecpar);
//    avcodec_parameters_to_context(_audioCodecContext, audioStream->codecpar);
////    av_codec_set_pkt_timebase(codec_ctx, stream->time_base);
//    if(audioCodec == NULL || videoCodec == NULL) {
//        printf("Couldn't find Codec.\n");
//        return;
//    }
//    if(avcodec_open2(self.audioCodecContext, audioCodec, NULL) < 0 || avcodec_open2(self.videoCodecContext, videoCodec, NULL) < 0) {
//        printf("Couldn't open codec.\n");
//        return;
//    }
//    
//    [self settingTimeBase];
//    [self settingDuration];
}

//- (void)closeFile {
//    AVFormatContext *p = formatContext.cContextPtr;
//    avcodec_close(_videoCodecContext);
//    avcodec_close(_audioCodecContext);
//    avformat_close_input(&p);
//}
//
//- (int)readFrame:(YuuPacket *)packet {
//    AVFormatContext *p = formatContext.cContextPtr;
//    return av_read_frame(p, packet.cPacketPtr);
//}

- (void)seekingTime:(NSTimeInterval)time {
    int64_t seek_pos = time * AV_TIME_BASE;
    int64_t seek_target = av_rescale_q(seek_pos, AV_TIME_BASE_Q, formatContext->streams[self.videoIndex]->time_base);
    av_seek_frame(formatContext, self.videoIndex, seek_target, AVSEEK_FLAG_BACKWARD);
}

//- (void)settingTimeBase {
//    YuuStream *stream = formatContext.streams[self.videoIndex];
//    if (stream.timebase.den > 0 && stream.timebase.num > 0) {
//        self.videoTimebase = av_q2d(stream.timebase);
//    } else {
//        NSAssert(NO, @"no time base");
//    }
//
//    YuuStream *audioStream = formatContext.streams[self.audioIndex];
//    if (audioStream.timebase.den > 0 && audioStream.timebase.num > 0) {
//        self.audioTimebase = av_q2d(audioStream.timebase);
//    } else {
//        NSAssert(NO, @"no time base");
//    }
//}
//
//- (void)settingDuration {
//    self.duration = formatContext.duration / AV_TIME_BASE;
//}

@end
