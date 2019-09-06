//
//  FrameUtil.h
//  Athena
//
//  Created by Skylar on 2019/8/22.
//  Copyright © 2019 Theresa. All rights reserved.
//

#ifndef FrameUtil_h
#define FrameUtil_h

#import <VideoToolbox/VideoToolbox.h>
#include <stdio.h>

long YuuYUVChannelFilterNeedSize(long linesize, long width, long height);
void YuuYUVChannelFilter(uint8_t * src, long linesize, long width, long height, uint8_t * dst, size_t dstsize);

void YuuDidDecompress(void *decompressionOutputRefCon,
                      void *sourceFrameRefCon,
                      OSStatus status,
                      VTDecodeInfoFlags infoFlags,
                      CVImageBufferRef pixelBuffer,
                      CMTime presentationTimeStamp,
                      CMTime presentationDuration);

void YuuAudioAccelerateCompute(float *player, UInt32 inNumberFrames, AudioBufferList *ioData) ;

#endif /* FrameUtil_h */
