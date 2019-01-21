//
//  TestUtil.m
//  Athena
//
//  Created by S.C. on 2019/1/19.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "TestUtil.h"
#import "libyuv.h"

@implementation TestUtil

+ (CVPixelBufferRef)createNV12From:(UIImage *)image {
    
    int width = image.size.width;
    int height = image.size.height;
    
    uint8_t *_outbuffer;
    uint8_t *_outbuffer_tmp;
    
    uint8_t *_outbuffer_yuv;
    uint8_t *_outbuffer_uv;
    
    int numBytes = width * height * 3 /2;
    _outbuffer = (uint8_t*)malloc(numBytes * sizeof(uint8_t));
    
    numBytes = width * height * 4;
    _outbuffer_tmp = (uint8_t*)malloc(numBytes * sizeof(uint8_t));
    
    numBytes = width * height * 3 / 2;
    _outbuffer_yuv = (uint8_t*)malloc(numBytes * sizeof(uint8_t));
    
    numBytes = width * height / 2;
    _outbuffer_uv = (uint8_t*)malloc(numBytes * sizeof(uint8_t));
    
    CVPixelBufferRef pixelBuffer;

    CGImageRef newCgImage = [image CGImage];
    CGDataProviderRef dataProvider = CGImageGetDataProvider(newCgImage);
    CFDataRef bitmapData = CGDataProviderCopyData(dataProvider);
    
    _outbuffer = (uint8_t *)CFDataGetBytePtr(bitmapData);
    

    ConvertToI420((uint8_t *)_outbuffer , width * height,
                  _outbuffer_yuv, width,
                  _outbuffer_yuv + width * height , width / 2 ,
                  _outbuffer_yuv + width * height * 5 / 4, width / 2 ,
                  0, 0,
                  width, height,
                  width, height,
                  0, FOURCC_ABGR);
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             //@(avframe->linesize[0]), kCVPixelBufferBytesPerRowAlignmentKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLESCompatibilityKey,
                             [NSDictionary dictionary], kCVPixelBufferIOSurfacePropertiesKey,
                             nil];
    
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                          width, height,
                                          kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange ,
                                          (__bridge CFDictionaryRef)(options),
                                          &pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t srcPlaneSize = width * height / 4;
    uint8_t *uDataAddr = _outbuffer_yuv + width * height;
    uint8_t *vDataAddr = uDataAddr + width * height / 4 ;
    
    for(size_t i = 0; i< srcPlaneSize; i++){
        _outbuffer_uv[2*i  ]=uDataAddr[i];
        _outbuffer_uv[2*i+1]=vDataAddr[i];
    }
    
    uint8_t *yDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    memcpy(yDestPlane, _outbuffer_yuv, width * height);
    
    uint8_t *uvDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    memcpy(uvDestPlane, _outbuffer_uv, width * height / 2);
    if (result != kCVReturnSuccess) {
        NSLog(@"Unable to create cvpixelbuffer %d", result);
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    free(_outbuffer);
    free(_outbuffer_tmp);
    free(_outbuffer_yuv);
    free(_outbuffer_uv);
    
    return pixelBuffer;
}

@end
