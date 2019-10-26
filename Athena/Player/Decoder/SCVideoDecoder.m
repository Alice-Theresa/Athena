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
#import "SCPacket.h"
#import "SCCodecContext.h"
#import "SCCodecDescriptor.h"

@interface SCVideoDecoder () {
    AVFrame *_temp_frame;
}

@property (nonatomic, strong) SCCodecContext *codecContext;
@property (nonatomic, strong) SCFormatContext *context;

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

- (void)checkCodec:(SCPacket *)packet {
    if (!self.codecContext) {
        self.codecContext = [[SCCodecContext alloc] initWithTimebase:packet.codecDescriptor.timebase
                                                            codecpar:packet.codecDescriptor.codecpar];
    }
}

- (NSArray<SCFrame *> *)decode:(SCPacket *)packet {
    [self checkCodec:packet];
    NSArray *defaultArray = @[];
    NSMutableArray *array = [NSMutableArray array];
    int result = avcodec_send_packet(self.codecContext.core, packet.core);
    if (result < 0) {
        return defaultArray;
    }
    while (result >= 0) {
        result = avcodec_receive_frame(self.codecContext.core, _temp_frame);
        if (result < 0) {
            if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                return defaultArray;
            }
            break;
        } else {
            SCI420VideoFrame *frame = [self videoFrameFromTempFrame:packet.core->size];
            if (frame) {
                [array addObject:frame];
            }
        }
    }
    return [array copy];
}

- (SCI420VideoFrame *)videoFrameFromTempFrame:(int)packetSize {
    if (!_temp_frame->data[0] || !_temp_frame->data[1] || !_temp_frame->data[2]) {
        return nil;
    }
    SCI420VideoFrame *videoFrame = [[SCI420VideoFrame alloc] initWithFrameData:_temp_frame
                                                                         width:self.codecContext.core->width
                                                                        height:self.codecContext.core->height];
    videoFrame.position = av_frame_get_best_effort_timestamp(_temp_frame) * self.context.videoTimebase;
    videoFrame.position += _temp_frame->repeat_pict * self.context.videoTimebase * 0.5;
    videoFrame.duration = av_frame_get_pkt_duration(_temp_frame) * self.context.videoTimebase;
    return videoFrame;
}

@end
