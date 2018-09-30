//
//  MainViewModel.m
//  Athena
//
//  Created by Theresa on 2018/9/28.
//  Copyright © 2018年 Theresa. All rights reserved.
//

#import "MainViewModel.h"
#import "MainModel.h"

@implementation MainViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    MainModel *model1 = [[MainModel alloc] init];
    model1.codecName = @"AAC解码";
    model1.vcName = @"AudioDecodeViewController";
    
    MainModel *model2 = [[MainModel alloc] init];
    model2.codecName = @"AAC编码";
    model2.vcName = @"AudioEncodeViewController";
    
    MainModel *model3 = [[MainModel alloc] init];
    model3.codecName = @"H264编码";
    model3.vcName = @"VideoEncodeViewController";
    
    self.codecNames = @[ model1, model2, model3 ];
}

@end
