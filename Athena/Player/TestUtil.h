//
//  TestUtil.h
//  Athena
//
//  Created by S.C. on 2019/1/19.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestUtil : NSObject

+ (CVPixelBufferRef)createNV12From:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
