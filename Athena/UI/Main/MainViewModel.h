//
//  MainViewModel.h
//  Athena
//
//  Created by Theresa on 2018/9/28.
//  Copyright © 2018年 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MainModel;

@interface MainViewModel : NSObject

@property (nonatomic, copy) NSArray<MainModel *> *codecNames;

@end

NS_ASSUME_NONNULL_END
