//
//  SCSWResample.h
//  Athena
//
//  Created by Skylar on 2019/11/3.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ALCAudioDescriptor;

@interface ALCSWResample : NSObject

@property (nonatomic, strong) ALCAudioDescriptor *inputDescriptor;
@property (nonatomic, strong) ALCAudioDescriptor *outputDescriptor;

- (BOOL)open;
- (int)write:(uint8_t **)data nb_samples:(int)nb_samples;
- (int)read:(uint8_t **)data nb_samples:(int)nb_samples;

@end
