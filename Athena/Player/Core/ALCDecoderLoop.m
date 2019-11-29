//
//  SCDecoderLayer.m
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "ALCDecoderLoop.h"
#import "ALCFormatContext.h"
#import "ALCMarker.h"
#import "ALCVideoDecoder.h"
#import "ALCAudioDecoder.h"
#import "ALCPacket.h"
#import "ALCVideoFrame.h"
#import "ALCPlayerState.h"
#import "ALCAudioFrame.h"
#import "ALCSWResample.h"
#import "ALCAudioDescriptor.h"
#import "ALCTrack.h"
#import "ALCFrameQueue.h"
#import "ALCPacketQueue.h"
#import "ALCCodecDescriptor.h"
#import "ALCDecoder.h"

@interface ALCDecoderLoop ()

@property (nonatomic, strong) ALCPacketQueue *packetQueue;
@property (nonatomic, strong) ALCFrameQueue *frameQueue;

@property (nonatomic, assign) BOOL isSeeking;
@property (nonatomic, strong) ALCFormatContext *context;
@property (nonatomic, assign) ALCPlayerState controlState;

@property (nonatomic, strong) NSOperationQueue *controlQueue;

@property (nonatomic, strong) ALCVideoDecoder *videoDecoder;
@property (nonatomic, strong) ALCAudioDecoder *audioDecoder;

@property (nonatomic, strong) ALCSWResample *resample;

@property (nonatomic, strong) NSCondition *wakeup;

@end

@implementation ALCDecoderLoop

- (void)dealloc {
    NSLog(@"decoder dealloc");
}

- (instancetype)initWithContext:(ALCFormatContext *)context packetQueue:(ALCPacketQueue *)packetQueue frameQueue:(ALCFrameQueue *)frameQueue {
    if (self = [super init]) {
        _context      = context;
        _packetQueue  = packetQueue;
        _frameQueue   = frameQueue;
        _videoDecoder = [[ALCVideoDecoder alloc] init];
        _audioDecoder = [[ALCAudioDecoder alloc] init];
        _controlQueue = [[NSOperationQueue alloc] init];
        _wakeup       = [[NSCondition alloc] init];
    }
    return self;
}

- (void)start {
    NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodeFrame) object:nil];
    [self.controlQueue addOperation:op];
    self.controlState = ALCPlayerStatePlaying;
}

- (void)resume {
    self.controlState = ALCPlayerStatePlaying;
    [self.wakeup lock];
    [self.wakeup broadcast];
    [self.wakeup unlock];
}

- (void)pause {
    self.controlState = ALCPlayerStatePaused;
}

- (void)close {
    self.controlState = ALCPlayerStateClosed;
    [self.controlQueue cancelAllOperations];
    [self.controlQueue waitUntilAllOperationsAreFinished];
}

- (void)decodeFrame {
    while (self.controlState != ALCPlayerStateClosed) {
        if (self.controlState == ALCPlayerStatePaused) {
            [self.wakeup lock];
            [self.wakeup wait];
            [self.wakeup unlock];
            continue;
        }
        @autoreleasepool {
            ALCPacket *packet = (ALCPacket *)[self.packetQueue dequeuePacket];
            if (!packet) {
                continue;
            }
            [self.frameQueue frameQueueIsFull:packet.codecDescriptor.track.type];
            id<ALCDecoder> decoder = packet.codecDescriptor.track.type == SCTrackTypeVideo ? self.videoDecoder : self.audioDecoder;
            if (packet.flowDataType == ALCFlowDataTypeDiscard) {
                ALCMarker *frame = [[ALCMarker alloc] init];
                frame.mediaType = packet.codecDescriptor.track.type == SCTrackTypeVideo ? ALCMediaTypeVideo : ALCMediaTypeAudio;
                [self.frameQueue flushFrameQueue:packet.codecDescriptor.track.type];
                [self.frameQueue enqueueFrames:@[frame]];
                [decoder flush];
                continue;
            }
            if (packet.core->data != NULL && packet.core->stream_index >= 0) {
                NSArray *frames = [decoder decode:packet];
                NSMutableArray *temp = [NSMutableArray array];
                for (ALCFlowData *frame in frames) {
                    frame.codecDescriptor = packet.codecDescriptor;
                    [temp addObject:[self process:frame]];
                }
                [self.frameQueue enqueueFrames:temp];
            }
        }
    }
}

- (ALCFlowData *)process:(ALCFlowData *)frame {
    if (frame.mediaType == ALCMediaTypeVideo) {
        return [self processVideo:(ALCVideoFrame *)frame];
    } else if (frame.mediaType == ALCMediaTypeAudio) {
        return [self processAudio:(ALCAudioFrame *)frame];
    } else {
        return nil;
    }
}

- (ALCVideoFrame *)processVideo:(ALCVideoFrame *)videoFrame {
    videoFrame.timeStamp = videoFrame.core->best_effort_timestamp * av_q2d(videoFrame.codecDescriptor.timebase);
    videoFrame.duration = videoFrame.core->pkt_duration * av_q2d(videoFrame.codecDescriptor.timebase);
    [videoFrame fillData];
    return videoFrame;
}

- (ALCAudioFrame *)processAudio:(ALCAudioFrame *)audioFrame {
    if (!self.resample) {
        self.resample = [[ALCSWResample alloc] init];
        self.resample.inputDescriptor = [[ALCAudioDescriptor alloc] initWithFrame:audioFrame];
        self.resample.outputDescriptor = [[ALCAudioDescriptor alloc] init];
        [self.resample open];
    }
    audioFrame.numberOfSamples = audioFrame.core->nb_samples;
    int nb_samples = [self.resample write:audioFrame.core->data nb_samples:audioFrame.numberOfSamples];
    
    ALCAudioFrame *frame = [ALCAudioFrame audioFrameWithDescriptor:self.resample.outputDescriptor numberOfSamples:nb_samples];
    int nb_planes = self.resample.outputDescriptor.numberOfPlanes;
    
    uint8_t *data[8] = { NULL };
    for (int i = 0; i < nb_planes; i++) {
        data[i] = frame.core->data[i];
    }
    [self.resample read:data nb_samples:nb_samples];
    [frame fillData];
    frame.timeStamp = audioFrame.core->best_effort_timestamp * av_q2d(audioFrame.codecDescriptor.timebase);
    frame.duration = audioFrame.core->pkt_duration * av_q2d(audioFrame.codecDescriptor.timebase);
    return frame;
}

@end
