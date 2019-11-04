//
//  SCAudioDecoder.m
//  Athena
//
//  Created by Theresa on 2019/01/09.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCAudioDecoder.h"
#import "SCFormatContext.h"
#import "SCAudioFrame.h"
#import "SCPacket.h"
#import "SCCodecContext.h"
#import "SCCodecDescriptor.h"
#import "SCSWResample.h"
#import "SCAudioDescriptor.h"

#include <libswresample/swresample.h>
#import <Accelerate/Accelerate.h>

@interface SCAudioDecoder ()

@property (nonatomic, strong) SCSWResample *resample;
@property (nonatomic, strong) SCCodecContext *codecContext;

@end

@implementation SCAudioDecoder

- (void)dealloc {
    NSLog(@"Audio Decoder dealloc");    
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
        self.codecContext = [[SCCodecContext alloc] initWithTimebase:packet.codecDescriptor.timebase codecpar:packet.codecDescriptor.codecpar];
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
        SCAudioFrame *frame = [[SCAudioFrame alloc] init];
        result = avcodec_receive_frame(self.codecContext.core, frame.core);
        if (result < 0) {
            if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                return defaultArray;
            }
            break;
        } else {
//            ;
            [array addObject:[self innerDecode:frame]];
        }
    }
    return [array copy];
}

- (SCAudioFrame *)innerDecode:(SCAudioFrame *)audioFrame {
    if (!self.resample) {
        self.resample = [[SCSWResample alloc] init];
        self.resample.inputDescriptor = [[SCAudioDescriptor alloc] initWithFrame:audioFrame];
        self.resample.outputDescriptor = [[SCAudioDescriptor alloc] init];
        [self.resample open];
    }
    [audioFrame fillData];
    int nb_samples = [self.resample write:audioFrame.data nb_samples:audioFrame.numberOfSamples];
    
    SCAudioFrame * frame = [self.class audioFrameWithDescriptor:self.resample.outputDescriptor numberOfSamples:nb_samples];
    
    int nb_planes = self.resample.outputDescriptor.numberOfPlanes;
    
    uint8_t *data[8] = { NULL };
    for (int i = 0; i < nb_planes; i++) {
        data[i] = frame.core->data[i];
    }
    [self.resample read:data nb_samples:nb_samples];
    [frame fillData];
    frame.timeStamp = av_frame_get_best_effort_timestamp(audioFrame.core) * self.context.audioTimebase;
    frame.duration = av_frame_get_pkt_duration(audioFrame.core) * self.context.audioTimebase;
    return frame;
}

+ (SCAudioFrame *)audioFrameWithDescriptor:(SCAudioDescriptor *)descriptor numberOfSamples:(int)numberOfSamples
{
    SCAudioFrame *frame = [[SCAudioFrame alloc] init];
    frame.core->format = descriptor.format;
    frame.core->sample_rate = descriptor.sampleRate;
    frame.core->channels = descriptor.numberOfChannels;
    frame.core->channel_layout = descriptor.channelLayout;
    frame.core->nb_samples = numberOfSamples;
    int linesize = [descriptor linesize:numberOfSamples];
    int numberOfPlanes = descriptor.numberOfPlanes;
    for (int i = 0; i < numberOfPlanes; i++) {
        uint8_t *data = av_mallocz(linesize);
        memset(data, 0, linesize);
        AVBufferRef *buffer = av_buffer_create(data, linesize, av_buffer_default_free, NULL, 0);
        frame.core->buf[i] = buffer;
        frame.core->data[i] = buffer->data;
        frame.core->linesize[i] = buffer->size;
    }
    return frame;
}

@end
