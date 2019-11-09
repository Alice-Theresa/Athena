//
//  SCDecoderLayer.m
//  Athena
//
//  Created by Skylar on 2019/10/14.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCDecoderLayer.h"
#import "SCFormatContext.h"
#import "SCControl.h"
#import "SCFrameQueue.h"
#import "SCFrame.h"
#import "SCMarkerFrame.h"
#import "SCPacketQueue.h"
#import "SCVideoDecoder.h"
#import "SCAudioDecoder.h"
#import "SCQueueProtocol.h"
#import "SCDemuxLayer.h"
#import "SCPacket.h"
#import "SCVideoFrame.h"
#import "SCPlayerState.h"
#import "SCAudioFrame.h"
#import "SCSWResample.h"
#import "SCAudioDescriptor.h"
#import "SCTrack.h"

@interface SCDecoderLayer () <DemuxToQueueProtocol>

@property (nonatomic, copy) NSDictionary<NSString *, SCPacketQueue *> *packetsQueue;
@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *> *timeStamps;

@property (nonatomic, assign) BOOL isSeeking;
@property (nonatomic, strong) SCFormatContext *context;
@property (nonatomic, assign) SCPlayerState controlState;

@property (nonatomic, strong) NSOperationQueue *controlQueue;

@property (nonatomic, strong) SCVideoDecoder *videoDecoder;
@property (nonatomic, strong) SCAudioDecoder *audioDecoder;

@property (nonatomic, strong) SCSWResample *resample;

@end

@implementation SCDecoderLayer

- (instancetype)initWithContext:(SCFormatContext *)context demuxLayer:(SCDemuxLayer *)demuxLayer{
    if (self = [super init]) {
        _context            = context;
        demuxLayer.delegate = self;
        _packetsQueue = [NSMutableDictionary dictionary];
        for (SCTrack *track in _context.tracks) {
            [_packetsQueue setValue:[[SCPacketQueue alloc] init] forKey:[NSString stringWithFormat:@"%d", track.index]];
        }
        _videoDecoder       = [[SCVideoDecoder alloc] init];
        _audioDecoder       = [[SCAudioDecoder alloc] init];
    }
    return self;
}

- (void)start {
    NSInvocationOperation *videoDecodeOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodeVideoFrame) object:nil];
    videoDecodeOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    videoDecodeOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    NSInvocationOperation *audioDecodeOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodeAudioFrame) object:nil];
    audioDecodeOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    audioDecodeOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    self.controlQueue = [[NSOperationQueue alloc] init];
    self.controlQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.controlQueue addOperation:videoDecodeOperation];
    [self.controlQueue addOperation:audioDecodeOperation];
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
        if ([self.delegate videoFrameQueueIsFull]) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        @autoreleasepool {
//            int streamIndex = -1;
//            double min = DBL_MAX;
//            for (NSString *key in self.packetsQueue) {
//                if (self.packetsQueue[key].packetTotalSize == 0) {
//                    continue;
//                }
//                NSNumber *time = self.timeStamps[key];
//                if (!time) {
//                    streamIndex = [key intValue];
//                    break;
//                }
//                double timestamp = [self.timeStamps[key] doubleValue];
//                if (timestamp < min) {
//                    min = timestamp;
//                    streamIndex = [key intValue];
//                    continue;
//                }
//            }
//            if (streamIndex == -1) {
//                continue;
//            }
            
            SCPacket *packet = [self.packetsQueue[@"0"] dequeuePacket];
            if (!packet) {
                continue;
            }
            if (packet.core->flags == AV_PKT_FLAG_DISCARD) {
                [self.videoDecoder flush];
                [self.delegate videoFrameQueueFlush];
                SCMarkerFrame *frame = [[SCMarkerFrame alloc] init];
                [self.delegate enqueueVideoFrames:@[frame]];
                continue;
            }
            if (packet.core->data != NULL && packet.core->stream_index >= 0) {
                NSArray<SCFrame *> *frames = [self.videoDecoder decode:packet];
                for (SCVideoFrame *frame in frames) {
                    [self process:frame];
                    [frame fillData];
                }
                [self.delegate enqueueVideoFrames:frames];
            }
        }
    }
}

- (void)decodeAudioFrame {
    while (self.controlState != SCPlayerStateClosed) {
        if (self.controlState == SCPlayerStatePaused) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if ([self.delegate audioFrameQueueIsFull]) {
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        @autoreleasepool {
            SCPacket *packet = [self.packetsQueue[@"1"] dequeuePacket];
            if (!packet) {
                continue;
            }
            if (packet.core->flags == AV_PKT_FLAG_DISCARD) {
                [self.audioDecoder flush];
                [self.delegate audioFrameQueueFlush];
                SCMarkerFrame *frame = [[SCMarkerFrame alloc] init];
                [self.delegate enqueueAudioFrames:@[frame]];
                continue;
            }
            if (packet.core->data != NULL && packet.core->stream_index >= 0) {
                NSArray<SCFrame *> *frames = [self.audioDecoder decode:packet];
                for (SCAudioFrame *frame in frames) {
                    [self innerDecode:frame];
                }
                [self.delegate enqueueAudioFrames:frames];
            }
        }
    }
}

# pragma mark - delegate

- (void)enqueue:(SCPacket *)packet {
    SCPacketQueue *queue = [self.packetsQueue valueForKey:[NSString stringWithFormat:@"%d", packet.core->stream_index]];
    [queue enqueuePacket:packet];
//    if (packet.core->stream_index == self.context.subtitleIndex) {
//        NSData *data = [[NSData alloc] initWithBytes:packet.core->data length:packet.core->size];
//        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSLog(@"%@", string);
//    }
}

- (void)flush {
    for (NSString *key in self.packetsQueue) {
        [self.packetsQueue[key] flush];
        [self.packetsQueue[key] enqueueDiscardPacket];
    }
}

- (BOOL)packetQueueIsFull {
    int total = 0;
    for (NSString *key in self.packetsQueue) {
        total += self.packetsQueue[key].packetTotalSize;
    }
    return total > 10 * 1024 * 1024;
}

- (void)process:(SCVideoFrame *)videoFrame {
    videoFrame.timeStamp = av_frame_get_best_effort_timestamp(videoFrame.core) * self.context.videoTimebase;
    videoFrame.timeStamp += videoFrame.core->repeat_pict * self.context.videoTimebase * 0.5;
    videoFrame.duration = av_frame_get_pkt_duration(videoFrame.core) * self.context.videoTimebase;
}

- (void)innerDecode:(SCAudioFrame *)audioFrame {
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
