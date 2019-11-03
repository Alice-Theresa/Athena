//
//  SCSWResample.h
//  Athena
//
//  Created by Skylar on 2019/11/3.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SCAudioDescriptor;

@interface SCSWResample : NSObject

@property (nonatomic, copy) SCAudioDescriptor *inputDescriptor;
@property (nonatomic, copy) SCAudioDescriptor *outputDescriptor;

@end

NS_ASSUME_NONNULL_END
