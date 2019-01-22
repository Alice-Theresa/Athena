//
//  SCVideoDecoder.m
//  Athena
//
//  Created by Theresa on 2019/01/07.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCVideoDecoder.h"
#import "SharedQueue.h"
#import "SCFormatContext.h"
#import "SCFrameQueue.h"
#import "SCNV12VideoFrame.h"
#import "SCI420VideoFrame.h"

@interface SCVideoDecoder () {
    AVFrame *_temp_frame;
}

@property (nonatomic, weak) SCFormatContext *formatContext;

@end

@implementation SCVideoDecoder

- (void)dealloc {
    av_frame_free(&_temp_frame);
}

- (instancetype)initWithFormatContext:(SCFormatContext *)formatContext {
    if (self = [super init]) {
        _formatContext = formatContext;
        _temp_frame = av_frame_alloc();
    }
    return self;
}

- (SCFrame *)decode:(AVPacket)packet {
    SCI420VideoFrame *videoFrame = nil;
    int result = avcodec_send_packet(self.formatContext.videoCodecContext, &packet);
    if (result < 0) {
        return nil;
    } else {
        while (result >= 0) {
            result = avcodec_receive_frame(self.formatContext.videoCodecContext, _temp_frame);
            if (result < 0) {
//                NSLog(@"error");
            } else {
                videoFrame = [self videoFrameFromTempFrame:packet.size];
            }
        }
    }
    av_packet_unref(&packet);
    return videoFrame;
}

- (SCI420VideoFrame *)videoFrameFromTempFrame:(int)packetSize {
    if (!_temp_frame->data[0] || !_temp_frame->data[1] || !_temp_frame->data[2]) {
        return nil;
    }
    SCI420VideoFrame *videoFrame = [[SCI420VideoFrame alloc] initWithFrameData:_temp_frame
                                                                         width:self.formatContext.videoCodecContext->width
                                                                        height:self.formatContext.videoCodecContext->height];
    videoFrame.position = av_frame_get_best_effort_timestamp(_temp_frame) * self.formatContext.videoTimebase;
    videoFrame.position += _temp_frame->repeat_pict * self.formatContext.videoTimebase * 0.5;
    videoFrame.duration = av_frame_get_pkt_duration(_temp_frame) * self.formatContext.videoTimebase;
    return videoFrame;
}

@end
