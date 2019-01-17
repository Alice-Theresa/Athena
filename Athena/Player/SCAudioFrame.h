//
//  SCAudioFrame.h
//  Athena
//
//  Created by Theresa on 2019/01/09.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface SCAudioFrame : SCFrame {
@public
    float *samples;
    int length;
    int output_offset;
}

- (void)setSamplesLength:(NSUInteger)samplesLength;

@end

NS_ASSUME_NONNULL_END
