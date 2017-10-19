//
//  AACHardwareDecoder.m
//  Athena
//
//  Created by Theresa on 2017/10/18.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "AACHardwareDecoder.h"

@interface AACHardwareDecoder () {
    AudioQueueRef playQueue;
}

@property (nonatomic, strong) NSMutableArray *buffers;

@end

@implementation AACHardwareDecoder

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)setup {
    
    AudioStreamBasicDescription pcmASBD = {0};
    


}



@end
