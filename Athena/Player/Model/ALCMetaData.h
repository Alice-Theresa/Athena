//
//  SCMetaData.h
//  Athena
//
//  Created by Theresa on 2019/01/31.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALCMetaData : NSObject

+ (instancetype)metadataWithAVDictionary:(AVDictionary *)avDictionary;

@property (nonatomic, strong) NSDictionary * metadata;

@property (nonatomic, copy  ) NSString     * language;
@property (nonatomic, assign) long long         BPS;
@property (nonatomic, copy  ) NSString     * duration;
@property (nonatomic, assign) long long         number_of_bytes;
@property (nonatomic, assign) long long         number_of_frames;

@end

NS_ASSUME_NONNULL_END
