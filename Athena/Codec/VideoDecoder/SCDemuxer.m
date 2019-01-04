//
//  SCDemuxer.m
//  Athena
//
//  Created by Theresa on 2018/12/29.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import "SCFormatContext.h"
#import "SCDemuxer.h"
#import "SCPacketQueue.h"
#import "SCVideoFrameQueue.h"
#import "SCHardwareDecoder.h"

@interface SCDemuxer ()

@property (nonatomic, strong) SCFormatContext *context;
@property (nonatomic, strong) SCHardwareDecoder *decoder;

@property (nonatomic, strong) dispatch_queue_t packetQueue;
@property (nonatomic, strong) dispatch_queue_t videoFrameQueue;

@end

@implementation SCDemuxer

- (instancetype)init {
    if (self = [super init]) {
        _context = [[SCFormatContext alloc] init];
        _decoder = [[SCHardwareDecoder alloc] initWithFormatContext:_context];
        _packetQueue = dispatch_queue_create("com.video.packet.queue", DISPATCH_QUEUE_SERIAL);
        _videoFrameQueue = dispatch_queue_create("com.video.frame.queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)startOperation {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (1) {
            AVPacket packet;
            av_init_packet(&packet);
            int result = [self.context readFrame:&packet];
            if (result < 0) {
                NSLog(@"read packet error");
                break;
            } else {
                if (packet.stream_index == self.context.videoIndex) {
                    dispatch_async(self.packetQueue, ^{
                        [[SCPacketQueue shared] putPacket:packet];
                    });
                }
               
                dispatch_async(self.videoFrameQueue, ^{
                    if ([SCVideoFrameQueue shared].count > 10) {
                        [NSThread sleepForTimeInterval:0.03];
                    }
                    [[SCVideoFrameQueue shared] putFrame:[self.decoder decode]];
                });
            }
        }
    });
}

@end
