//
//  SCAudioDecoder.m
//  Athena
//
//  Created by Theresa on 2019/01/09.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "ALCAudioDecoder.h"
#import "ALCFormatContext.h"
#import "ALCAudioFrame.h"
#import "ALCPacket.h"
#import "ALCCodecContext.h"
#import "ALCCodecDescriptor.h"

@interface ALCAudioDecoder ()

@property (nonatomic, strong) ALCCodecContext *codecContext;

@end

@implementation ALCAudioDecoder

- (void)dealloc {
    NSLog(@"Audio Decoder dealloc");    
}

- (void)flush {
    [self.codecContext flush];
}

- (void)checkCodec:(ALCPacket *)packet {
    if (!self.codecContext) {
        self.codecContext = [[ALCCodecContext alloc] initWithTimebase:packet.codecDescriptor.timebase
                                                            codecpar:packet.codecDescriptor.codecpar
                                                          frameClass:[ALCAudioFrame class]];
    }
}

- (NSArray<id<ALCFrame>> *)decode:(ALCPacket *)packet {
    [self checkCodec:packet];
    return [self.codecContext decode:packet];
}

@end
