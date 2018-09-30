//
//  AudioSoftDecoder.h
//  Athena
//
//  Created by Theresa on 2018/9/28.
//  Copyright © 2018年 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AudioSoftDecoder;

@protocol AudioPlayerDelegate <NSObject>

- (void)onPlayToEnd:(AudioSoftDecoder *)decoder;

@end

@interface AudioSoftDecoder : NSObject

@property (nonatomic, weak) id<AudioPlayerDelegate> delegate;

- (void)play;

@end
