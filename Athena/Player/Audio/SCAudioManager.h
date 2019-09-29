//
//  SCAudioManager.h
//  Athena
//
//  Created by Theresa on 2019/01/10.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SCAudioManagerDelegate <NSObject>

- (void)fetchoutputData:(SInt16 *)outputData numberOfFrames:(UInt32)numberOfFrames numberOfChannels:(UInt32)numberOfChannels;

@end

@interface SCAudioManager : NSObject

+ (instancetype)shared;

@property (nonatomic, weak) id<SCAudioManagerDelegate> delegate;

- (void)play;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
