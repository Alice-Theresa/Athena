//
//  AudioSoftDecoder.m
//  Athena
//
//  Created by Theresa on 2018/9/28.
//  Copyright © 2018年 Theresa. All rights reserved.
//

#define INPUT_BUS 1
#define OUTPUT_BUS 0
#define MAX_AUDIO_FRAME_SIZE 192000
#define OUT_PUT_CHANNELS 2
#define STMAX(a, b)  (((a) > (b)) ? (a) : (b))
#define STMIN(a, b)  (((a) < (b)) ? (a) : (b))

#include <libavutil/opt.h>
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>
#include <libavutil/samplefmt.h>

#import <AVFoundation/AVFoundation.h>
#import <AudioUnit/AudioUnit.h>
#import "AudioSoftDecoder.h"

const uint32_t CONST_BUFFER_SIZE = 0x10000;


@interface AudioSoftDecoder () {
    AudioUnit audioUnit;
    AudioBufferList *buffList;
    NSInputStream *inputSteam;
    
    AVCodecContext *codecContext;
    AVFormatContext *avFormatContext;
    AVCodec *codec;
    AVPacket packet;
    AVFrame *frame;
    uint8_t *frameBuf;
    long length;
    long oneSecBytes;
    int stream_index;
    float timeBase;
    int packetBufferSize;
    
    char *pcmBuffer;
    size_t pcmBufferSize;
    
    short* _audioBuffer;
    SwrContext *swrContext;
    void * _swrBuffer;
    
    uint8_t *out_buffer;
    int64_t in_channel_layout;
    int index;
    
    NSMutableData *temp;
    int index2;
}

@end

@implementation AudioSoftDecoder

- (instancetype)init
{
    self = [super init];
    if (self) {
        temp = [NSMutableData data];
    }
    return self;
}

- (void)play {
//    [self initFFMpeg];
    [self initPlayer];
    AudioOutputUnitStart(audioUnit);

}


- (void)initFFMpeg {
    NSString *fileName = @"abc.pcm";
    NSString *audioFile = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileName];
    [[NSFileManager defaultManager] removeItemAtPath:audioFile error:nil];
    [[NSFileManager defaultManager] createFileAtPath:audioFile contents:nil attributes:nil];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:audioFile];
    
    av_register_all();
    avcodec_register_all();
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
    int ret = avcodec_parameters_to_context(codecContext, audioStream->codecpar);
    
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
            [fileHandle writeData:myData];
            @synchronized (self) {
                [temp appendData:myData];
            }
            
            printf("index:%5d\t pts:%lld\t packet size:%d\n", index, packet.pts, packet.size);
            index++;
        }
    }
    [fileHandle closeFile];
}

- (void)initPlayer {
    // open pcm stream
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"abc" withExtension:@"pcm"];
    inputSteam = [NSInputStream inputStreamWithURL:url];
    if (!inputSteam) {
        NSLog(@"打开文件失败 %@", url);
    }
    else {
        [inputSteam open];
    }
    
    OSStatus status = noErr;
    
    AudioComponentDescription audioDesc;
    audioDesc.componentType = kAudioUnitType_Output;
    audioDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    audioDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    audioDesc.componentFlags = 0;
    audioDesc.componentFlagsMask = 0;
    
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &audioDesc);
    AudioComponentInstanceNew(inputComponent, &audioUnit);
    
    // buffer
    buffList = (AudioBufferList *)malloc(sizeof(AudioBufferList));
    buffList->mNumberBuffers = 1;
    buffList->mBuffers[0].mNumberChannels = 2;
    buffList->mBuffers[0].mDataByteSize = CONST_BUFFER_SIZE;
    buffList->mBuffers[0].mData = malloc(CONST_BUFFER_SIZE);
    
    //audio property
    UInt32 flag = 1;
    if (flag) {
        status = AudioUnitSetProperty(audioUnit,
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
    
    status = AudioUnitSetProperty(audioUnit,
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
    AudioUnitSetProperty(audioUnit,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Input,
                         OUTPUT_BUS,
                         &playCallback,
                         sizeof(playCallback));
    
    
    OSStatus result = AudioUnitInitialize(audioUnit);
    NSLog(@"result %d", result);
}



static OSStatus PlayCallback(void *inRefCon,
                             AudioUnitRenderActionFlags *ioActionFlags,
                             const AudioTimeStamp *inTimeStamp,
                             UInt32 inBusNumber,
                             UInt32 inNumberFrames,
                             AudioBufferList *ioData) {
    AudioSoftDecoder *player = (__bridge AudioSoftDecoder *)inRefCon;
    
    ioData->mBuffers[0].mDataByteSize = (UInt32)[player->inputSteam read:ioData->mBuffers[0].mData maxLength:(NSInteger)ioData->mBuffers[0].mDataByteSize];
    NSLog(@"out size: %d", ioData->mBuffers[0].mDataByteSize);

    if (ioData->mBuffers[0].mDataByteSize <= 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [player stop];
        });
    }
    return noErr;
}


- (void)stop {
    AudioOutputUnitStop(audioUnit);
    if (buffList != NULL) {
        if (buffList->mBuffers[0].mData) {
            free(buffList->mBuffers[0].mData);
            buffList->mBuffers[0].mData = NULL;
        }
        free(buffList);
        buffList = NULL;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayToEnd:)]) {
        __strong typeof (AudioSoftDecoder) *player = self;
        [self.delegate onPlayToEnd:player];
    }
    
    [inputSteam close];
}

- (void)dealloc {
    AudioOutputUnitStop(audioUnit);
    AudioUnitUninitialize(audioUnit);
    AudioComponentInstanceDispose(audioUnit);
    
    if (buffList != NULL) {
        free(buffList);
        buffList = NULL;
    }
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
