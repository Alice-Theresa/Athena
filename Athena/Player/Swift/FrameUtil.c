//
//  FrameUtil.c
//  Athena
//
//  Created by Skylar on 2019/8/22.
//  Copyright © 2019 Theresa. All rights reserved.
//

#define MIN(X, Y) (((X) < (Y)) ? (X) : (Y))

#import <Accelerate/Accelerate.h>
#import <libavformat/avformat.h>
#include "FrameUtil.h"

long YuuYUVChannelFilterNeedSize(long linesize, long width, long height) {
    width = MIN(linesize, width);
    return width * height;
}

void YuuYUVChannelFilter(uint8_t * src, long linesize, long width, long height, uint8_t * dst, size_t dstsize) {
    width = MIN(linesize, width);
    uint8_t * temp = dst;
    memset(dst, 0, dstsize);
    for (int i = 0; i < height; i++) {
        memcpy(temp, src, width);
        temp += width;
        src += linesize;
    }
}

void YuuDidDecompress(void *decompressionOutputRefCon,
                      void *sourceFrameRefCon,
                      OSStatus status,
                      VTDecodeInfoFlags infoFlags,
                      CVImageBufferRef pixelBuffer,
                      CMTime presentationTimeStamp,
                      CMTime presentationDuration) {
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

void YuuAudioAccelerateCompute(float *player, UInt32 inNumberFrames, AudioBufferList *ioData) {
    float scale = (float)INT16_MAX;
    vDSP_vsmul(player, 1, &scale, player, 1, inNumberFrames * 2);
    
    for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; iBuffer++) {
        int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
        for (int iChannel = 0; iChannel < thisNumChannels; iChannel++) {
            vDSP_vfix16(player + iChannel,
                        2,
                        (SInt16 *)ioData->mBuffers[iBuffer].mData + iChannel,
                        thisNumChannels,
                        inNumberFrames);
        }
    }
}
