//
//  VideoDecoder.m
//  Athena
//
//  Created by Theresa on 2018/12/24.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <VideoToolbox/VideoToolbox.h>
#import "SCHardwareDecoder.h"
#import "SharedQueue.h"
#import "SCFormatContext.h"
#import "SCPacketQueue.h"
#import "SCVideoFrameQueue.h"
#import "SCVideoFrame.h"

@interface SCHardwareDecoder () {
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
    SCFormatContext *context;
}

@end

static void didDecompress(void *decompressionOutputRefCon,
                          void *sourceFrameRefCon,
                          OSStatus status,
                          VTDecodeInfoFlags infoFlags,
                          CVImageBufferRef pixelBuffer,
                          CMTime presentationTimeStamp,
                          CMTime presentationDuration ) {
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

@implementation SCHardwareDecoder

- (void)dealloc {
    if(_deocderSession) {
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
    if(_decoderFormatDescription) {
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
}

- (instancetype)initWithFormatContext:(SCFormatContext *)formatContext {
    if (self = [super init]) {
        [self initDecoderWithFormatContext:formatContext];
    }
    return self;
}

- (BOOL)initDecoderWithFormatContext:(SCFormatContext *)formatContext {
    if(_deocderSession) {
        return YES;
    }
    context = formatContext;
    AVCodecContext *codecContext = [formatContext fetchCodecContext];
    uint8_t *extradata = codecContext->extradata;
    int extradata_size = codecContext->extradata_size;
    
    if (extradata_size < 7 || extradata == NULL) {
        return NO;
    }
    if (extradata[0] != 1) {
        return NO;
    } else {
        _decoderFormatDescription = CreateFormatDescription(kCMVideoCodecType_H264, codecContext->width, codecContext->height, extradata, extradata_size);
        if (_decoderFormatDescription == NULL) {
            NSLog(@"create decoder format description failed");
            return NO;
        }
        
        CFMutableDictionaryRef destinationPixelBufferAttributes = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        cf_dict_set_int32(destinationPixelBufferAttributes, kCVPixelBufferPixelFormatTypeKey, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange);
        cf_dict_set_int32(destinationPixelBufferAttributes, kCVPixelBufferWidthKey, codecContext->width);
        cf_dict_set_int32(destinationPixelBufferAttributes, kCVPixelBufferHeightKey, codecContext->height);
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = (__bridge void *)self;
        
        OSStatus status = VTDecompressionSessionCreate(kCFAllocatorDefault, _decoderFormatDescription, NULL,
                                                       destinationPixelBufferAttributes, &callBackRecord, &_deocderSession);
        if(status != noErr) {
            NSLog(@"Create Decompression Session failed - Code= %d", status);
            return NO;
        } else {
            return YES;
        }
    }
}

- (SCVideoFrame *)decode {
    CVPixelBufferRef outputPixelBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    AVPacket packet = [[SCPacketQueue shared] getPacket];
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, (void*)packet.data, packet.size, kCFAllocatorNull,
                                                          NULL, 0, packet.size, FALSE, &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        status = CMSampleBufferCreate(NULL, blockBuffer, TRUE, 0, 0, _decoderFormatDescription, 1, 0, NULL, 0, NULL, &sampleBuffer);
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession, sampleBuffer, 0, &outputPixelBuffer, NULL);
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT: Invalid session, reset decoder session");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT: decode failed status=%d(Bad data)", decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS8VT: decode failed status=%d", decodeStatus);
            }
            NSLog(@"Read Nalu size %ld", packet.size);
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    SCVideoFrame *videoFrame = [[SCVideoFrame alloc] initWithAVPixelBuffer:outputPixelBuffer];
    videoFrame.position = packet.pts * context.videoTimebase;
    return videoFrame;
}

static CMFormatDescriptionRef CreateFormatDescription(CMVideoCodecType codec_type, int width, int height, const uint8_t * extradata, int extradata_size)
{
    CMFormatDescriptionRef format_description = NULL;
    OSStatus status;
    
    CFMutableDictionaryRef par = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef atoms = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef extensions = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    // CVPixelAspectRatio
    cf_dict_set_int32(par, CFSTR("HorizontalSpacing"), 0);
    cf_dict_set_int32(par, CFSTR("VerticalSpacing"), 0);
    
    // SampleDescriptionExtensionAtoms
    cf_dict_set_data(atoms, CFSTR("avcC"), (uint8_t *)extradata, extradata_size);
    
    // Extensions
    cf_dict_set_string(extensions, CFSTR ("CVImageBufferChromaLocationBottomField"), "left");
    cf_dict_set_string(extensions, CFSTR ("CVImageBufferChromaLocationTopField"), "left");
    cf_dict_set_boolean(extensions, CFSTR("FullRangeVideo"), FALSE);
    cf_dict_set_object(extensions, CFSTR ("CVPixelAspectRatio"), (CFTypeRef *)par);
    cf_dict_set_object(extensions, CFSTR ("SampleDescriptionExtensionAtoms"), (CFTypeRef *)atoms);
    
    status = CMVideoFormatDescriptionCreate(NULL, codec_type, width, height, extensions, &format_description);
    
    CFRelease(extensions);
    CFRelease(atoms);
    CFRelease(par);
    
    if (status != noErr) {
        return NULL;
    }
    return format_description;
}

static void cf_dict_set_data(CFMutableDictionaryRef dict, CFStringRef key, uint8_t * value, uint64_t length)
{
    CFDataRef data;
    data = CFDataCreate(NULL, value, (CFIndex)length);
    CFDictionarySetValue(dict, key, data);
    CFRelease(data);
}

static void cf_dict_set_int32(CFMutableDictionaryRef dict, CFStringRef key, int32_t value)
{
    CFNumberRef number;
    number = CFNumberCreate(NULL, kCFNumberSInt32Type, &value);
    CFDictionarySetValue(dict, key, number);
    CFRelease(number);
}

static void cf_dict_set_string(CFMutableDictionaryRef dict, CFStringRef key, const char * value)
{
    CFStringRef string;
    string = CFStringCreateWithCString(NULL, value, kCFStringEncodingASCII);
    CFDictionarySetValue(dict, key, string);
    CFRelease(string);
}

static void cf_dict_set_boolean(CFMutableDictionaryRef dict, CFStringRef key, BOOL value)
{
    CFDictionarySetValue(dict, key, value ? kCFBooleanTrue: kCFBooleanFalse);
}

static void cf_dict_set_object(CFMutableDictionaryRef dict, CFStringRef key, CFTypeRef *value)
{
    CFDictionarySetValue(dict, key, value);
}

@end
