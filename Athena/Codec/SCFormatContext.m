//
//  SCFormatContext.m
//  Athena
//
//  Created by Theresa on 2018/12/25.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import "SCFormatContext.h"
#import "SCPacketQueue.h"

@implementation SCFormatContext {
    AVCodecContext *codecContext;
    AVFormatContext *formatContext;
    AVCodec *codec;
    AVFrame *frame;
    int videoindex;
}

- (AVCodecContext *)fetchCodecContext {
    return codecContext;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setupDecoder];
        for (int i = 0; i < 1000; i++) {
            [[SCPacketQueue shared] putPacket:[self readFrame]];
        }
    }
    return self;
}

- (void)setupDecoder {
    av_register_all();
    avformat_network_init();
    formatContext = avformat_alloc_context();

    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"vid.mp4"];
    
    if(avformat_open_input(&formatContext, [path UTF8String], NULL, NULL) != 0){
        printf("Couldn't open input stream.\n");
        return ;
    }
    if(avformat_find_stream_info(formatContext,NULL)<0){
        printf("Couldn't find stream information.\n");
        return;
    }
    videoindex = -1;
    for(int i = 0; i < formatContext->nb_streams; i++)
        if(formatContext->streams[i]->codecpar->codec_type==AVMEDIA_TYPE_VIDEO){
            videoindex = i;
            break;
        }
    if(videoindex == -1){
        printf("Couldn't find a video stream.\n");
        return;
    }
    
    codecContext = formatContext->streams[videoindex]->codec;
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

- (AVPacket)readFrame {
    AVPacket packet;
    av_init_packet(&packet);
    int res = av_read_frame(self->formatContext, &packet);
    int nalu_type = (packet.data[4] & 0x1F);
    return packet;
}

@end
