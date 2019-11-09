//
//  SCVideoDecoder.m
//  Athena
//
//  Created by Theresa on 2019/01/07.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCVideoDecoder.h"
#import "SharedQueue.h"
#import "SCFormatContext.h"
#import "SCVideoFrame.h"
#import "SCPacket.h"
#import "SCFrame.h"
#import "SCCodecContext.h"
#import "SCCodecDescriptor.h"

@interface SCVideoDecoder ()

@property (nonatomic, strong) SCCodecContext *codecContext;

@end

@implementation SCVideoDecoder

- (void)dealloc {
    NSLog(@"Video Decoder dealloc");    
}

- (void)flush {
    [self.codecContext flush];
}

- (void)checkCodec:(SCPacket *)packet {
    if (!self.codecContext) {
        self.codecContext = [[SCCodecContext alloc] initWithTimebase:packet.codecDescriptor.timebase
                                                            codecpar:packet.codecDescriptor.codecpar
                                                          frameClass:[SCVideoFrame class]];
    }
}

- (NSArray<SCFrame *> *)decode:(SCPacket *)packet {
    [self checkCodec:packet];
    return [self.codecContext decode:packet];
}

@end
