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
#import "SCVideoFrame.h"
#import "SCPacket.h"
#import "SCFrame.h"
#import "SCCodecContext.h"
#import "SCCodecDescriptor.h"

@interface SCVideoDecoder ()

@property (nonatomic, strong) SCCodecContext *codecContext;
@property (nonatomic, strong) SCFormatContext *context;

@end

@implementation SCVideoDecoder

- (void)dealloc {
    NSLog(@"Video Decoder dealloc");    
}

- (instancetype)initWithFormatContext:(SCFormatContext *)formatContext {
    if (self = [super init]) {
        _context = formatContext;
    }
    return self;
}

- (void)flush {
    [self.codecContext flush];
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
        SCVideoFrame *frame = [[SCVideoFrame alloc] init];
        result = avcodec_receive_frame(self.codecContext.core, frame.core);
        if (result < 0) {
            if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                return defaultArray;
            }
            break;
        } else {
            [self process:frame];
            [array addObject:frame];
        }
    }
    return [array copy];
}

- (void)process:(SCFrame *)videoFrame {
    videoFrame.timeStamp = av_frame_get_best_effort_timestamp(videoFrame.core) * self.context.videoTimebase;
    videoFrame.timeStamp += videoFrame.core->repeat_pict * self.context.videoTimebase * 0.5;
    videoFrame.duration = av_frame_get_pkt_duration(videoFrame.core) * self.context.videoTimebase;
}

@end
