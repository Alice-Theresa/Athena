//
//  SCAudioFrame.m
//  Athena
//
//  Created by Theresa on 2019/01/09.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCAudioFrame.h"

@implementation SCAudioFrame {
    size_t buffer_size;
}

- (void)setSamplesLength:(NSUInteger)samplesLength {
    if (buffer_size < samplesLength) {
        if (buffer_size > 0 && samples != NULL) {
            free(samples);
        }
        buffer_size = samplesLength;
        samples = malloc(buffer_size);
    }
    length = (int)samplesLength;
    output_offset = 0;
}

- (void)dealloc {
    free(samples);
}

@end
