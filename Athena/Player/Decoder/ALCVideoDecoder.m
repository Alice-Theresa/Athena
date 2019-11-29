//
//  SCVideoDecoder.m
//  Athena
//
//  Created by Theresa on 2019/01/07.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "ALCVideoDecoder.h"
#import "SharedQueue.h"
#import "ALCFormatContext.h"
#import "ALCVideoFrame.h"
#import "ALCPacket.h"
#import "ALCCodecContext.h"
#import "ALCCodecDescriptor.h"

@interface ALCVideoDecoder ()

@property (nonatomic, strong) ALCCodecContext *codecContext;

@end

@implementation ALCVideoDecoder

- (void)dealloc {
    NSLog(@"Video Decoder dealloc");    
}

- (void)flush {
    [self.codecContext flush];
}

- (void)checkCodec:(ALCPacket *)packet {
    if (!self.codecContext) {
        self.codecContext = [[ALCCodecContext alloc] initWithTimebase:packet.codecDescriptor.timebase
                                                            codecpar:packet.codecDescriptor.codecpar
                                                          frameClass:[ALCVideoFrame class]];
    }
}

- (NSArray<id<ALCFrame>> *)decode:(ALCPacket *)packet {
    [self checkCodec:packet];
    return [self.codecContext decode:packet];
}

@end
