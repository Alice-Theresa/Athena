//
//  SCSoftwareDecoder.m
//  Athena
//
//  Created by Theresa on 2019/01/07.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCSoftwareDecoder.h"
#import "SharedQueue.h"
#import "SCFormatContext.h"
#import "SCPacketQueue.h"
#import "SCFrameQueue.h"
#import "SCVideoFrame.h"

@interface SCSoftwareDecoder () {
    AVFrame *_temp_frame;
}

@property (nonatomic, strong) SCFormatContext *formatContext;

@end

@implementation SCSoftwareDecoder

- (instancetype)initWithFormatContext:(SCFormatContext *)formatContext {
    if (self = [super init]) {
        _formatContext = formatContext;
    }
    return self;
}

- (SCVideoFrame *)decode {
    SCVideoFrame *videoFrame = nil;
    AVPacket packet = [[SCPacketQueue shared] getPacket];
    int result = avcodec_send_packet(self.formatContext.videoCodecContext, &packet);
    if (result < 0) {
        return nil;
    } else {
        while (result >= 0) {
            result = avcodec_receive_frame(self.formatContext.videoCodecContext, _temp_frame);
            if (result < 0) {
                return nil;
            } else {
                videoFrame = [self videoFrameFromTempFrame:packet.size];
            }
        }
    }
    av_packet_unref(&packet);
    

    return videoFrame;
}

- (SCVideoFrame *)videoFrameFromTempFrame:(int)packetSize {
    if (!_temp_frame->data[0] || !_temp_frame->data[1] || !_temp_frame->data[2]) {
        return nil;
    }
    SCVideoFrame *videoFrame = [[SCVideoFrame alloc] init];
    
    videoFrame.position = av_frame_get_best_effort_timestamp(_temp_frame) * self.formatContext.videoTimebase;
    videoFrame.position += _temp_frame->repeat_pict * self.formatContext.videoTimebase * 0.5;
    videoFrame.duration = av_frame_get_pkt_duration(_temp_frame) * self.formatContext.videoTimebase;
    return videoFrame;
}

@end
