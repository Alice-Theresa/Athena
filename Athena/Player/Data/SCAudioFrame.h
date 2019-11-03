//
//  SCAudioFrame.h
//  Athena
//
//  Created by Theresa on 2019/01/09.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface SCAudioFrame : SCFrame

@property (nonatomic, strong) NSData *sampleData;
@property (nonatomic, assign) NSInteger outputOffset;

@end

NS_ASSUME_NONNULL_END
