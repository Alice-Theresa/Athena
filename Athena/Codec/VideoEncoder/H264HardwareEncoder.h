//
//  H264HardwareEncoder.h
//  Athena
//
//  Created by Theresa on 2017/10/20.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "H264EncoderInterface.h"
#import "H264EncoderDelegate.h"

@interface H264HardwareEncoder : NSObject <H264EncoderInterface>

@property (nonatomic, weak) id<H264EncoderDelegate> delegate;
    
@end
