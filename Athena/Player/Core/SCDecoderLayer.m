//
//  SCDecoderLayer.m
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCDecoderLayer.h"
#import "SCFormatContext.h"
#import "SCMarkerFrame.h"
#import "SCVideoDecoder.h"
#import "SCAudioDecoder.h"
#import "SCPacket.h"
#import "SCVideoFrame.h"
#import "SCPlayerState.h"
#import "SCAudioFrame.h"
#import "SCSWResample.h"
#import "SCAudioDescriptor.h"
#import "SCTrack.h"
#import "ALCQueueManager.h"
#import "SCCodecDescriptor.h"

@interface SCDecoderLayer ()

@property (nonatomic, strong) ALCQueueManager *manager;

@property (nonatomic, assign) BOOL isSeeking;
@property (nonatomic, strong) SCFormatContext *context;
@property (nonatomic, assign) SCPlayerState controlState;

@property (nonatomic, strong) NSOperationQueue *controlQueue;

@property (nonatomic, strong) SCVideoDecoder *videoDecoder;
@property (nonatomic, strong) SCAudioDecoder *audioDecoder;

@property (nonatomic, strong) SCSWResample *resample;

@end

@implementation SCDecoderLayer

- (instancetype)initWithContext:(SCFormatContext *)context queueManager:(ALCQueueManager *)manager {
    if (self = [super init]) {
        _context      = context;
        _manager      = manager;
        _videoDecoder = [[SCVideoDecoder alloc] init];
        _audioDecoder = [[SCAudioDecoder alloc] init];
        _controlQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)start {
    
    NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodeVideoFrame) object:nil];
    [self.controlQueue addOperation:op];
    self.controlState = SCPlayerStatePlaying;
}

- (void)resume {
    self.controlState = SCPlayerStatePlaying;
}

- (void)pause {
    self.controlState = SCPlayerStatePaused;
}

- (void)close {
    self.controlState = SCPlayerStateClosed;
    [self.controlQueue cancelAllOperations];
    [self.controlQueue waitUntilAllOperationsAreFinished];
}

- (void)decodeVideoFrame {
    while (self.controlState != SCPlayerStateClosed) {
        if (self.controlState == SCPlayerStatePaused) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        @autoreleasepool {
            SCPacket *packet = [self.manager dequeuePacket];
            if (!packet) {
                continue;
            }
            if (packet.codecDescriptor.track.type == SCTrackTypeVideo) {
                [self.manager videoFrameQueueIsFull];
            } else if (packet.codecDescriptor.track.type == SCTrackTypeAudio) {
                [self.manager audioFrameQueueIsFull];
            }
            if (packet.core->flags == AV_PKT_FLAG_DISCARD) {
                SCMarkerFrame *frame = [[SCMarkerFrame alloc] init];
                if (packet.codecDescriptor.track.type == SCTrackTypeVideo) {
                    [self.manager videoFrameQueueIsFull];
                    [self.videoDecoder flush];
                    [self.manager videoFrameQueueFlush];
                    [self.manager enqueueVideoFrames:@[frame]];
                } else if (packet.codecDescriptor.track.type == SCTrackTypeAudio) {
                    [self.manager audioFrameQueueIsFull];
                    [self.audioDecoder flush];
                    [self.manager audioFrameQueueFlush];
                    [self.manager enqueueAudioFrames:@[frame]];
                }
                continue;
            }
            if (packet.core->data != NULL && packet.core->stream_index >= 0) {
                if (packet.codecDescriptor.track.type == SCTrackTypeVideo) {
                    NSArray<SCFrame *> *frames = [self.videoDecoder decode:packet];
                    for (SCVideoFrame *frame in frames) {
                        frame.codecDescriptor = packet.codecDescriptor;
                        [self process:frame];
                    }
                    [self.manager enqueueVideoFrames:frames];
                } else if (packet.codecDescriptor.track.type == SCTrackTypeAudio) {
                    NSArray<SCFrame *> *frames = [self.audioDecoder decode:packet];
                    NSMutableArray *temp = [NSMutableArray array];
                    for (SCAudioFrame *frame in frames) {
                        frame.codecDescriptor = packet.codecDescriptor;
//                        [self innerDecode:frame];
                        [temp addObject:[self innerDecode:frame]];
                    }
                    [self.manager enqueueAudioFrames:temp];
                }

            }
        }
    }
}

- (void)process:(SCVideoFrame *)videoFrame {
//    videoFrame.
    videoFrame.timeStamp = av_frame_get_best_effort_timestamp(videoFrame.core) * self.context.videoTimebase;
    videoFrame.timeStamp += videoFrame.core->repeat_pict * self.context.videoTimebase * 0.5;
    videoFrame.duration = av_frame_get_pkt_duration(videoFrame.core) * self.context.videoTimebase;
    [videoFrame fillData];
}

- (SCAudioFrame *)innerDecode:(SCAudioFrame *)audioFrame {
    if (!self.resample) {
        self.resample = [[SCSWResample alloc] init];
        self.resample.inputDescriptor = [[SCAudioDescriptor alloc] initWithFrame:audioFrame];
        self.resample.outputDescriptor = [[SCAudioDescriptor alloc] init];
        [self.resample open];
    }
    audioFrame.numberOfSamples = audioFrame.core->nb_samples;
    int nb_samples = [self.resample write:audioFrame.core->data nb_samples:audioFrame.numberOfSamples];
    
    SCAudioFrame *frame = [SCAudioFrame audioFrameWithDescriptor:self.resample.outputDescriptor numberOfSamples:nb_samples];
    
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

@end
