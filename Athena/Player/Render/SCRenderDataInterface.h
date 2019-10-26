//
//  SCRenderDataInterface.h
//  Athena
//
//  Created by Theresa on 2019/01/18.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <libavformat/avformat.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SCRenderDataInterface <NSObject>

@property (nonatomic, assign, readonly) NSUInteger width;
@property (nonatomic, assign, readonly) NSUInteger height;

@end

NS_ASSUME_NONNULL_END
