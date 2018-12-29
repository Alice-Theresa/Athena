//
//  SCFormatContext.m
//  Athena
//
//  Created by Theresa on 2018/12/25.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import "SCFormatContext.h"
#import "SCPacketQueue.h"

@interface SCFormatContext () {
    AVCodecContext *codecContext;
    AVFormatContext *formatContext;
    AVCodec *codec;
}

@end

@implementation SCFormatContext

- (AVCodecContext *)fetchCodecContext {
    return codecContext;
}

- (instancetype)init {
    if (self = [super init]) {
        _videoIndex = -1;
        [self setupDecoder];
    }
    return self;
}

- (void)setupDecoder {
    av_register_all();
    avformat_network_init();
    formatContext = avformat_alloc_context();

    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"test.mp4"];
    
    if(avformat_open_input(&formatContext, [path UTF8String], NULL, NULL) != 0){
        printf("Couldn't open input stream.\n");
        return ;
    }
    if(avformat_find_stream_info(formatContext,NULL)<0){
        printf("Couldn't find stream information.\n");
        return;
    }
    
    for(int i = 0; i < formatContext->nb_streams; i++)
        if(formatContext->streams[i]->codecpar->codec_type==AVMEDIA_TYPE_VIDEO){
            self.videoIndex = i;
            break;
        }
    if(self.videoIndex == -1){
        printf("Couldn't find a video stream.\n");
        return;
    }
    
    codecContext = formatContext->streams[self.videoIndex]->codec;
    codec = avcodec_find_decoder(codecContext->codec_id);
    if(codec == NULL){
        printf("Couldn't find Codec.\n");
        return;
    }
    if(avcodec_open2(codecContext, codec, NULL) < 0){
        printf("Couldn't open codec.\n");
        return;
    }
    
}

- (int)readFrame:(AVPacket *)packet {
    return av_read_frame(self->formatContext, packet);
}

@end
