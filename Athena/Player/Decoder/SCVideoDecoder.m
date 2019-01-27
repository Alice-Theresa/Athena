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
#import "SCNV12VideoFrame.h"
#import "SCI420VideoFrame.h"

@interface SCVideoDecoder () {
    AVFrame *_temp_frame;
}

@property (nonatomic, weak) SCFormatContext *context;
@property (nonatomic, assign) NSUInteger counter;
@end

@implementation SCVideoDecoder

- (void)dealloc {
    av_frame_free(&_temp_frame);
    NSLog(@"Video Decoder dealloc");    
}

- (instancetype)initWithFormatContext:(SCFormatContext *)formatContext {
    if (self = [super init]) {
        _context = formatContext;
        _temp_frame = av_frame_alloc();
    }
    return self;
}

- (NSArray<SCFrame *> *)decode:(AVPacket)packet {
    NSArray *defaultArray = @[];
    NSMutableArray *array = [NSMutableArray array];
    int result = avcodec_send_packet(self.context.videoCodecContext, &packet);
    if (result < 0) {
        return defaultArray;
    }
    while (result >= 0) {
        result = avcodec_receive_frame(self.context.videoCodecContext, _temp_frame);
        if (result < 0) {
            if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                return defaultArray;
            }
            break;
        } else {
            SCI420VideoFrame *frame = [self videoFrameFromTempFrame:packet.size];
            if (frame) {
                [array addObject:frame];
            }
        }
    }
    av_packet_unref(&packet);
    return [array copy];
}

- (SCI420VideoFrame *)videoFrameFromTempFrame:(int)packetSize {
    if (!_temp_frame->data[0] || !_temp_frame->data[1] || !_temp_frame->data[2]) {
        return nil;
    }
    
    if (AV_PICTURE_TYPE_I == _temp_frame->pict_type) {
        printf("%d\n", self.counter);
        self.counter = 0;
    }
    self.counter++;
    SCI420VideoFrame *videoFrame = [[SCI420VideoFrame alloc] initWithFrameData:_temp_frame
                                                                         width:self.context.videoCodecContext->width
                                                                        height:self.context.videoCodecContext->height];
    videoFrame.position = av_frame_get_best_effort_timestamp(_temp_frame) * self.context.videoTimebase;
    videoFrame.position += _temp_frame->repeat_pict * self.context.videoTimebase * 0.5;
    videoFrame.duration = av_frame_get_pkt_duration(_temp_frame) * self.context.videoTimebase;
    return videoFrame;
}

@end
