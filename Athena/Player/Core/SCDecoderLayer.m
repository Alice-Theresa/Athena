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
#import "SCDecoder.h"

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
    NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodeFrame) object:nil];
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

- (void)decodeFrame {
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
            [self.manager frameQueueIsFull:packet.codecDescriptor.track.type];
            id<SCDecoder> decoder = packet.codecDescriptor.track.type == SCTrackTypeVideo ? self.videoDecoder : self.audioDecoder;
            if (packet.flowDataType == SCFlowDataTypeDiscard) {
                SCMarkerFrame *frame = [[SCMarkerFrame alloc] init];
                frame.type = packet.codecDescriptor.track.type == SCTrackTypeVideo ? SCMediaTypeVideo : SCMediaTypeAudio;
                [self.manager flushFrameQueue:packet.codecDescriptor.track.type];
                [self.manager enqueueFrames:@[frame]];
                [decoder flush];
                continue;
            }
            if (packet.core->data != NULL && packet.core->stream_index >= 0) {
                NSArray *frames = [decoder decode:packet];
                for (id<SCFrame> frame in frames) {
                    frame.codecDescriptor = packet.codecDescriptor;
                    [self process:frame];
                }
                [self.manager enqueueFrames:frames];
            }
        }
    }
}

- (void)process:(id<SCFrame>)frame {
    if (frame.type == SCMediaTypeVideo) {
        [self processVideo:frame];
    } else if (frame.type == SCMediaTypeAudio) {
        [self processAudio:frame];
    }
}

- (void)processVideo:(SCVideoFrame *)videoFrame {
    videoFrame.timeStamp = av_frame_get_best_effort_timestamp(videoFrame.core) * self.context.videoTimebase;
    videoFrame.timeStamp += videoFrame.core->repeat_pict * self.context.videoTimebase * 0.5;
    videoFrame.duration = av_frame_get_pkt_duration(videoFrame.core) * self.context.videoTimebase;
    [videoFrame fillData];
}

- (void)processAudio:(SCAudioFrame *)audioFrame {
    if (!self.resample) {
        self.resample = [[SCSWResample alloc] init];
        self.resample.inputDescriptor = [[SCAudioDescriptor alloc] initWithFrame:audioFrame];
        self.resample.outputDescriptor = [[SCAudioDescriptor alloc] init];
        [self.resample open];
    }
    audioFrame.numberOfSamples = audioFrame.core->nb_samples;
    int nb_samples = [self.resample write:audioFrame.core->data nb_samples:audioFrame.numberOfSamples];
    
    [audioFrame createBuffer:self.resample.outputDescriptor numberOfSamples:nb_samples];
    int nb_planes = self.resample.outputDescriptor.numberOfPlanes;
    
    uint8_t *data[8] = { NULL };
    for (int i = 0; i < nb_planes; i++) {
        data[i] = audioFrame.core->data[i];
    }
    [self.resample read:data nb_samples:nb_samples];
    [audioFrame fillData];
    audioFrame.timeStamp = av_frame_get_best_effort_timestamp(audioFrame.core) * self.context.audioTimebase;
    audioFrame.duration = av_frame_get_pkt_duration(audioFrame.core) * self.context.audioTimebase;
}

@end
