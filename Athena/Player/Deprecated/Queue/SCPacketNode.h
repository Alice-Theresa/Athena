//
//  SCPacketNode.h
//  Athena
//
//  Created by Theresa on 2019/01/29.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCPacketNode : NSObject

@property (nonatomic, strong, readonly) NSValue *packet;
@property (nonatomic, strong) SCPacketNode *next;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPacket:(NSValue *)packet;

@end

NS_ASSUME_NONNULL_END
