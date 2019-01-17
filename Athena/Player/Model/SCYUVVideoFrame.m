//
//  SCYUVVideoFrame.m
//  Athena
//
//  Created by Theresa on 2019/01/17.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import "SCYUVVideoFrame.h"

@implementation SCYUVVideoFrame {
    size_t channel_pixels_buffer_size[SGYUVChannelCount];
    int channel_lenghts[SGYUVChannelCount];
    int channel_linesize[SGYUVChannelCount];
}


- (void)setFrameData:(AVFrame *)frame width:(int)width height:(int)height {
    
    int linesize_y = frame->linesize[SGYUVChannelLuma];
    int linesize_u = frame->linesize[SGYUVChannelChromaB];
    int linesize_v = frame->linesize[SGYUVChannelChromaR];
    
    channel_linesize[SGYUVChannelLuma] = linesize_y;
    channel_linesize[SGYUVChannelChromaB] = linesize_u;
    channel_linesize[SGYUVChannelChromaR] = linesize_v;
    
    UInt8 * buffer_y = channel_pixels[SGYUVChannelLuma];
    UInt8 * buffer_u = channel_pixels[SGYUVChannelChromaB];
    UInt8 * buffer_v = channel_pixels[SGYUVChannelChromaR];
    
    size_t buffer_size_y = channel_pixels_buffer_size[SGYUVChannelLuma];
    size_t buffer_size_u = channel_pixels_buffer_size[SGYUVChannelChromaB];
    size_t buffer_size_v = channel_pixels_buffer_size[SGYUVChannelChromaR];
    
    int need_size_y = SGYUVChannelFilterNeedSize(linesize_y, width, height, 1);
    channel_lenghts[SGYUVChannelLuma] = need_size_y;
    if (buffer_size_y < need_size_y) {
        if (buffer_size_y > 0 && buffer_y != NULL) {
            free(buffer_y);
        }
        channel_pixels_buffer_size[SGYUVChannelLuma] = need_size_y;
        channel_pixels[SGYUVChannelLuma] = malloc(need_size_y);
    }
    int need_size_u = SGYUVChannelFilterNeedSize(linesize_u, width / 2, height / 2, 1);
    channel_lenghts[SGYUVChannelChromaB] = need_size_u;
    if (buffer_size_u < need_size_u) {
        if (buffer_size_u > 0 && buffer_u != NULL) {
            free(buffer_u);
        }
        channel_pixels_buffer_size[SGYUVChannelChromaB] = need_size_u;
        channel_pixels[SGYUVChannelChromaB] = malloc(need_size_u);
    }
    int need_size_v = SGYUVChannelFilterNeedSize(linesize_v, width / 2, height / 2, 1);
    channel_lenghts[SGYUVChannelChromaR] = need_size_v;
    if (buffer_size_v < need_size_v) {
        if (buffer_size_v > 0 && buffer_v != NULL) {
            free(buffer_v);
        }
        channel_pixels_buffer_size[SGYUVChannelChromaR] = need_size_v;
        channel_pixels[SGYUVChannelChromaR] = malloc(need_size_v);
    }
    
    SGYUVChannelFilter(frame->data[SGYUVChannelLuma],
                       linesize_y,
                       width,
                       height,
                       channel_pixels[SGYUVChannelLuma],
                       channel_pixels_buffer_size[SGYUVChannelLuma],
                       1);
    SGYUVChannelFilter(frame->data[SGYUVChannelChromaB],
                       linesize_u,
                       width / 2,
                       height / 2,
                       channel_pixels[SGYUVChannelChromaB],
                       channel_pixels_buffer_size[SGYUVChannelChromaB],
                       1);
    SGYUVChannelFilter(frame->data[SGYUVChannelChromaR],
                       linesize_v,
                       width / 2,
                       height / 2,
                       channel_pixels[SGYUVChannelChromaR],
                       channel_pixels_buffer_size[SGYUVChannelChromaR],
                       1);
}

int SGYUVChannelFilterNeedSize(int linesize, int width, int height, int channel_count) {
    width = MIN(linesize, width);
    return width * height * channel_count;
}

void SGYUVChannelFilter(UInt8 * src, int linesize, int width, int height, UInt8 * dst, size_t dstsize, int channel_count) {
    width = MIN(linesize, width);
    UInt8 * temp = dst;
    memset(dst, 0, dstsize);
    for (int i = 0; i < height; i++) {
        memcpy(temp, src, width * channel_count);
        temp += (width * channel_count);
        src += linesize;
    }
}

@end
