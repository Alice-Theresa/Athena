//
//  AudioDecoder.h
//  Athena
//
//  Created by Theresa on 2018/9/28.
//  Copyright © 2018年 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AudioDecoder;

@protocol AudioPlayerDelegate <NSObject>

- (void)onPlayToEnd:(AudioDecoder *)decoder;

@end

@interface AudioDecoder : NSObject

@property (nonatomic, weak) id<AudioPlayerDelegate> delegate;

- (void)play;

@end
