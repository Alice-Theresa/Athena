//
//  SCAudioDecoder.m
//  Athena
//
//  Created by Theresa on 2019/01/09.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCAudioDecoder.h"
#import "SCFormatContext.h"
#import "SCAudioFrame.h"
#import "SCPacket.h"
#import "SCCodecContext.h"
#import "SCCodecDescriptor.h"

@interface SCAudioDecoder ()

@property (nonatomic, strong) SCCodecContext *codecContext;

@end

@implementation SCAudioDecoder

- (void)dealloc {
    NSLog(@"Audio Decoder dealloc");    
}

- (void)flush {
    [self.codecContext flush];
}

- (void)checkCodec:(SCPacket *)packet {
    if (!self.codecContext) {
        self.codecContext = [[SCCodecContext alloc] initWithTimebase:packet.codecDescriptor.timebase
                                                            codecpar:packet.codecDescriptor.codecpar
                                                          frameClass:[SCAudioFrame class]];
    }
}

- (NSArray<SCFrame *> *)decode:(SCPacket *)packet {
    [self checkCodec:packet];
    return [self.codecContext decode:packet];
}

@end
