//
//  SCSWResample.h
//  Athena
//
//  Created by Skylar on 2019/11/3.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCAudioDescriptor;

@interface SCSWResample : NSObject

@property (nonatomic, strong) SCAudioDescriptor *inputDescriptor;
@property (nonatomic, strong) SCAudioDescriptor *outputDescriptor;

- (BOOL)open;
- (int)write:(uint8_t **)data nb_samples:(int)nb_samples;
- (int)read:(uint8_t **)data nb_samples:(int)nb_samples;

@end
