//
//  SCFlowData.h
//  Athena
//
//  Created by Skylar on 2019/10/31.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SCFlowData <NSObject>

@property (nonatomic, assign) NSTimeInterval timeStamp;
@property (nonatomic, assign) NSTimeInterval duration;

@end

NS_ASSUME_NONNULL_END
