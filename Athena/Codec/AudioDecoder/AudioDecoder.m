//
//  AudioDecoder.m
//  Athena
//
//  Created by Theresa on 2018/9/28.
//  Copyright © 2018年 Theresa. All rights reserved.
//

#define INPUT_BUS 1
#define OUTPUT_BUS 0
#define MAX_AUDIO_FRAME_SIZE 192000
#define OUT_PUT_CHANNELS 2

#include <libavutil/opt.h>
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>
#include <libavutil/samplefmt.h>

#import <AVFoundation/AVFoundation.h>
#import <AudioUnit/AudioUnit.h>
#import "AudioDecoder.h"

const uint32_t CONST_BUFFER_SIZE = 0x10000;

@interface AudioDecoder () {
    
    AVCodecContext *codecContext;
    AVFormatContext *avFormatContext;
    AVCodec *codec;
    AVPacket packet;
    AVFrame *frame;
    int stream_index;
    
    SwrContext *swrContext;
    uint8_t *out_buffer;
    int64_t in_channel_layout;
}

@property (nonatomic, assign) AudioUnit audioUnit;

@property (nonatomic, strong) NSMutableData *temp;
@property (nonatomic, strong) NSInputStream *inputSteam;

@end

@implementation AudioDecoder

- (instancetype)init {
    if (self = [super init]) {
        _temp = [NSMutableData data];
    }
    return self;
}

- (void)play {
    [self initFFMpeg];
    [self initPlayer];
    AudioOutputUnitStart(self.audioUnit);
}

- (void)initFFMpeg {
    av_register_all();
    avFormatContext = avformat_alloc_context();
    
    NSString *url = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"abc.mp3"];
    int result = avformat_open_input(&avFormatContext, url.UTF8String, NULL, NULL);
    if (result != 0) {
        NSLog(@"can not open file -- code:%d", result);
        return;
    }
    
    result = avformat_find_stream_info(avFormatContext, NULL);
    if (result < 0) {
        printf("can not find stream info \n");
        return;
    }
    
    stream_index = av_find_best_stream(avFormatContext, AVMEDIA_TYPE_AUDIO, -1, -1, &codec, 0);
    if (stream_index == -1) {
        NSLog(@"没有音频流...");
        return;
    }
    
    AVStream *audioStream = avFormatContext->streams[stream_index];
    codec = avcodec_find_decoder(audioStream->codecpar->codec_id);
    

    codecContext = avcodec_alloc_context3(codec);
    avcodec_parameters_to_context(codecContext, audioStream->codecpar);
    
    //Out Audio Param
    uint64_t out_channel_layout=AV_CH_LAYOUT_STEREO;
    //nb_samples: AAC-1024 MP3-1152
    int out_nb_samples = codecContext->frame_size;
    enum AVSampleFormat out_sample_fmt = AV_SAMPLE_FMT_S16;
    int out_sample_rate = 44100;
    int out_channels = av_get_channel_layout_nb_channels(out_channel_layout);
    //Out Buffer Size
    int out_buffer_size = av_samples_get_buffer_size(NULL,out_channels ,out_nb_samples,out_sample_fmt, 1);
    
    out_buffer = (uint8_t *)av_malloc(MAX_AUDIO_FRAME_SIZE*2);
    frame = av_frame_alloc();
    
    //FIX:Some Codec's Context Information is missing
    in_channel_layout = av_get_default_channel_layout(codecContext->channels);
    //Swr
    swrContext = swr_alloc();
    swrContext = swr_alloc_set_opts(swrContext,out_channel_layout, out_sample_fmt, out_sample_rate,
                                      in_channel_layout,codecContext->sample_fmt , codecContext->sample_rate,0, NULL);
    swr_init(swrContext);
    
    if (avcodec_open2(codecContext, codec, NULL) >= 0) {
        frame = av_frame_alloc();
    }
    av_init_packet(&packet);
    
    while (av_read_frame(avFormatContext, &packet) >= 0) {
        if (packet.stream_index == stream_index) {
            int result = avcodec_send_packet(codecContext, &packet);
            if (result < 0 && result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                
            }
            result = avcodec_receive_frame(codecContext, frame);
            swr_convert(swrContext, &out_buffer, MAX_AUDIO_FRAME_SIZE,(const uint8_t **)frame->data , frame->nb_samples);
            
            NSData *myData = [[NSData alloc] initWithBytes:out_buffer length:out_buffer_size];
            [self.temp appendData:myData];
        }
    }
}

- (void)initPlayer {
    // open pcm stream
    self.inputSteam = [NSInputStream inputStreamWithData:self.temp];
    if (!self.inputSteam) {
        NSLog(@"打开文件失败");
    } else {
        [self.inputSteam open];
    }
    
    OSStatus status = noErr;
    
    AudioComponentDescription audioDesc;
    audioDesc.componentType = kAudioUnitType_Output;
    audioDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    audioDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    audioDesc.componentFlags = 0;
    audioDesc.componentFlagsMask = 0;
    
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &audioDesc);
    AudioComponentInstanceNew(inputComponent, &_audioUnit);
    
    //audio property
    UInt32 flag = 1;
    if (flag) {
        status = AudioUnitSetProperty(self.audioUnit,
                                      kAudioOutputUnitProperty_EnableIO,
                                      kAudioUnitScope_Output,
                                      OUTPUT_BUS,
                                      &flag,
                                      sizeof(flag));
    }
    if (status) {
        NSLog(@"AudioUnitSetProperty error with status:%d", status);
    }
    
    // format
    AudioStreamBasicDescription outputFormat;
    memset(&outputFormat, 0, sizeof(outputFormat));
    outputFormat.mSampleRate       = 44100; // 采样率
    outputFormat.mFormatID         = kAudioFormatLinearPCM; // PCM格式
    outputFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger; // 整形
    outputFormat.mFramesPerPacket  = 1; // 每帧只有1个packet
    outputFormat.mChannelsPerFrame = 2; // 声道数
    outputFormat.mBytesPerFrame    = 4; // 每帧只有2个byte 声道*位深*Packet数
    outputFormat.mBytesPerPacket   = 4; // 每个Packet只有2个byte
    outputFormat.mBitsPerChannel   = 16; // 位深
    [self printAudioStreamBasicDescription:outputFormat];
    
    status = AudioUnitSetProperty(self.audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  OUTPUT_BUS,
                                  &outputFormat,
                                  sizeof(outputFormat));
    if (status) {
        NSLog(@"AudioUnitSetProperty eror with status:%d", status);
    }
    
    
    // callback
    AURenderCallbackStruct playCallback;
    playCallback.inputProc = PlayCallback;
    playCallback.inputProcRefCon = (__bridge void *)self;
    AudioUnitSetProperty(self.audioUnit,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Input,
                         OUTPUT_BUS,
                         &playCallback,
                         sizeof(playCallback));
    
    
    OSStatus result = AudioUnitInitialize(self.audioUnit);
    NSLog(@"result %d", result);
}



static OSStatus PlayCallback(void *inRefCon,
                             AudioUnitRenderActionFlags *ioActionFlags,
                             const AudioTimeStamp *inTimeStamp,
                             UInt32 inBusNumber,
                             UInt32 inNumberFrames,
                             AudioBufferList *ioData) {
    for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; iBuffer++) {
        memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
    }
    
    AudioDecoder *player = (__bridge AudioDecoder *)inRefCon;
    
    ioData->mBuffers[0].mDataByteSize = (UInt32)[player.inputSteam read:ioData->mBuffers[0].mData maxLength:(NSInteger)ioData->mBuffers[0].mDataByteSize];
    NSLog(@"out size: %d", ioData->mBuffers[0].mDataByteSize);

    if (ioData->mBuffers[0].mDataByteSize <= 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [player stop];
        });
    }
    return noErr;
}


- (void)stop {
    AudioOutputUnitStop(self.audioUnit);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayToEnd:)]) {
        __strong typeof (AudioDecoder) *player = self;
        [self.delegate onPlayToEnd:player];
    }
    
    [self.inputSteam close];
}

- (void)dealloc {
    AudioOutputUnitStop(self.audioUnit);
    AudioUnitUninitialize(self.audioUnit);
    AudioComponentInstanceDispose(self.audioUnit);
}

- (void)printAudioStreamBasicDescription:(AudioStreamBasicDescription)asbd {
    char formatID[5];
    UInt32 mFormatID = CFSwapInt32HostToBig(asbd.mFormatID);
    bcopy (&mFormatID, formatID, 4);
    formatID[4] = '\0';
    printf("Sample Rate:         %10.0f\n",  asbd.mSampleRate);
    printf("Format ID:           %10s\n",    formatID);
    printf("Format Flags:        %10X\n",    (unsigned int)asbd.mFormatFlags);
    printf("Bytes per Packet:    %10d\n",    (unsigned int)asbd.mBytesPerPacket);
    printf("Frames per Packet:   %10d\n",    (unsigned int)asbd.mFramesPerPacket);
    printf("Bytes per Frame:     %10d\n",    (unsigned int)asbd.mBytesPerFrame);
    printf("Channels per Frame:  %10d\n",    (unsigned int)asbd.mChannelsPerFrame);
    printf("Bits per Channel:    %10d\n",    (unsigned int)asbd.mBitsPerChannel);
    printf("\n");
}


@end
