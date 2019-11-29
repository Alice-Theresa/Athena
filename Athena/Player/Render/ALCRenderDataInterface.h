//
//  SCRenderDataInterface.h
//  Athena
//
//  Created by Theresa on 2019/01/18.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ALCRenderDataInterface <NSObject>

@property (nonatomic, assign, readonly) NSUInteger width;
@property (nonatomic, assign, readonly) NSUInteger height;

@end
