//
//  SCFormatContext.m
//  Athena
//
//  Created by Theresa on 2018/12/25.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import "SCFormatContext.h"

@interface SCFormatContext () {
    AVFormatContext *formatContext;
    AVCodec *videoCodec;
    AVCodec *audioCodec;
}

@property (nonatomic, assign, readwrite) int videoIndex;
@property (nonatomic, assign, readwrite) int audioIndex;
@property (nonatomic, assign, readwrite) NSTimeInterval videoTimebase;
@property (nonatomic, assign, readwrite) NSTimeInterval audioTimebase;

@property (nonatomic, assign, readwrite) NSTimeInterval duration;

@end

@implementation SCFormatContext

- (instancetype)init {
    if (self = [super init]) {
        _videoIndex = -1;
        _audioIndex = -1;
        [self setupDecoder];
    }
    return self;
}

- (void)setupDecoder {
    av_register_all();
    avformat_network_init();
    formatContext = avformat_alloc_context();
}

- (void)openFile:(NSString *)filename {
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
    
    if(avformat_open_input(&formatContext, [path UTF8String], NULL, NULL) != 0){
        printf("Couldn't open input stream.\n");
        return ;
    }
    if(avformat_find_stream_info(formatContext, NULL) < 0){
        printf("Couldn't find stream information.\n");
        return;
    }
    
    for (int i = 0; i < formatContext->nb_streams; i++) {
        if (formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            self.videoIndex = i;
        } else if (formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            self.audioIndex = i;  // maybe multi audio track
            break;
        }
    }
    if (self.videoIndex == -1) {
        printf("Couldn't find a video stream.\n");
//        return;
    }
    
    _videoCodecContext = formatContext->streams[self.videoIndex]->codec;
    _audioCodecContext = formatContext->streams[self.audioIndex]->codec;
    
    videoCodec = avcodec_find_decoder(self.videoCodecContext->codec_id);
    audioCodec = avcodec_find_decoder(self.audioCodecContext->codec_id);
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
    avformat_close_input(&formatContext);
    avcodec_close(_videoCodecContext);
    avcodec_close(_audioCodecContext);
}

- (int)readFrame:(AVPacket *)packet {
    return av_read_frame(formatContext, packet);
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
