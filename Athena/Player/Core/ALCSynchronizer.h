//
//  SCSynchronizer.h
//  Athena
//
//  Created by Theresa on 2019/01/30.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALCSynchronizer : NSObject

- (void)updateAudioClock:(NSTimeInterval)position;
- (BOOL)shouldRenderVideoFrame:(NSTimeInterval)position duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
