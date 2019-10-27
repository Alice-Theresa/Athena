//
//  SCVideoFrame.h
//  Athena
//
//  Created by Theresa on 2018/12/28.
//  Copyright © 2018 Theresa. All rights reserved.
//

#import <libavformat/avformat.h>
#import <AVFoundation/AVFoundation.h>
#import "SCFrame.h"
#import "SCRenderDataInterface.h"

@interface SCVideoFrame : SCFrame

@property (nonatomic, assign, readonly) NSUInteger width;
@property (nonatomic, assign, readonly) NSUInteger height;

@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;

//- (int *)linesize;
- (uint8_t **)data;
- (void)fillData;

@end

