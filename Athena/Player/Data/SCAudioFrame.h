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
    int output_offset;
}

@property (nonatomic, strong) NSData *sampleData;

@end

NS_ASSUME_NONNULL_END
