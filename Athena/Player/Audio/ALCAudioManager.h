//
//  SCAudioManager.h
//  Athena
//
//  Created by Theresa on 2019/01/10.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SCAudioManagerDelegate <NSObject>

- (void)fetchoutputData:(AudioBufferList *)outputData numberOfFrames:(UInt32)numberOfFrames;

@end

@interface ALCAudioManager : NSObject

+ (instancetype)shared;

@property (nonatomic, weak) id<SCAudioManagerDelegate> delegate;

- (void)play;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
