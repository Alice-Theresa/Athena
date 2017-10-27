//
//  H264SoftwareEncoder.m
//  Athena
//
//  Created by Theresa on 2017/10/25.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#include <libavformat/avformat.h>
#include <libavutil/imgutils.h>

#import <AVFoundation/AVFoundation.h>
#import "H264SoftwareEncoder.h"

@interface H264SoftwareEncoder () {
    AVCodecContext *codecContext;
    AVCodec *codec;
    AVPacket packet;
    AVFrame *frame;
}
    
@property (nonatomic, assign) NSInteger frameID;
    
@end

@implementation H264SoftwareEncoder

- (instancetype)init {
    if (self = [super init]) {
        _frameID = 0;
        [self setupEncoder];
    }
    return self;
}
    
- (void)setupEncoder {
    int frameWidth = 720;
    int frameHeight = 1280;
    avcodec_register_all();
    codecContext = avcodec_alloc_context3(codec);
    codecContext->codec_id   = AV_CODEC_ID_H264;
    codecContext->codec_type = AVMEDIA_TYPE_VIDEO;
    codecContext->pix_fmt    = AV_PIX_FMT_YUV420P;

    codecContext->width         = frameWidth;
    codecContext->height        = frameHeight;
    codecContext->time_base.num = 1;
    codecContext->time_base.den = 30;
    codecContext->bit_rate      = 1024 * 1000;
    codecContext->gop_size      = 60;
    codecContext->qmin          = 10;
    codecContext->qmax          = 51;
    codecContext->thread_count  = 5;
    codecContext->thread_type   = FF_THREAD_FRAME;
    
    AVDictionary *param = NULL;
    if(codecContext->codec_id == AV_CODEC_ID_H264) {
        av_dict_set(&param, "preset", "slow", 0);
        av_dict_set(&param, "tune", "zerolatency", 0);
        av_dict_set(&param, "profile", "main", 0);
    }
    
    codec = avcodec_find_encoder(codecContext->codec_id);
    if (!codec) {
        NSAssert(NO, @"Can not find encoder!");
    }
    
    if (avcodec_open2(codecContext, codec, &param) < 0) {
        NSAssert(NO, @"Failed to open encoder!");
    }
    
    frame = av_frame_alloc();
    frame->width = frameWidth;
    frame->height = frameHeight;
    frame->format = AV_PIX_FMT_YUV420P;
    av_image_fill_arrays(frame->data,
                         frame->linesize,
                         NULL,
                         codecContext->pix_fmt,
                         codecContext->width,
                         codecContext->height,
                         1);
    int pictureSize = av_image_get_buffer_size(codecContext->pix_fmt, codecContext->width, codecContext->height, 1);
    av_new_packet(&packet, pictureSize);
}
    
- (void)encodeSampleBuffer:(CVImageBufferRef)imageBuffer {
    CVPixelBufferLockBaseAddress(imageBuffer, 0);

    UInt8 *pY = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    UInt8 *pUV = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t pYBytes = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    size_t pUVBytes = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1);
    
    UInt8 *pYUV420P = (UInt8 *)malloc(width * height * 3 / 2); // buffer to store YUV with layout YYYYYYYYUUVV
    
    /* convert NV12 data to YUV420*/
    UInt8 *pU = pYUV420P + (width * height);
    UInt8 *pV = pU + (width * height / 4);
    for(int i = 0; i < height; i++) {
        memcpy(pYUV420P + i * width, pY + i * pYBytes, width);
    }
    for(int j = 0; j < height / 2; j++) {
        for(int i = 0; i < width / 2; i++) {
            *(pU++) = pUV[i<<1];
            *(pV++) = pUV[(i<<1) + 1];
        }
        pUV += pUVBytes;
    }
    
    //Read raw YUV data
    frame->data[0] = pYUV420P;                               // Y
    frame->data[1] = frame->data[0] + width * height;        // U
    frame->data[2] = frame->data[1] + (width * height) / 4;  // V
    // PTS
    frame->pts = self.frameID;
    // Encode
    if (!codecContext) {
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        return;
    }
    int ret = avcodec_send_frame(codecContext, frame);
    ret = avcodec_receive_packet(codecContext, &packet);
    if(ret < 0) {
        NSLog(@"Failed to encode!");
    }
    if(ret == 0) {
        NSLog(@"Succeed to encode frame: %ld\tsize:%5d", self.frameID, packet.size);
        self.frameID++;
        NSData *data = [NSData dataWithBytes:packet.data length:packet.size];
        [self.delegate encodedResult:data error:nil];
        
        av_packet_unref(&packet);
    }
    
    free(pYUV420P);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

- (void)teardown {
    avcodec_close(codecContext);
    av_free(codecContext);
//    av_frame_free(&frame);
    av_free(frame);
    codecContext = NULL;
    frame = NULL;
}

@end
