//
//  SCPlayerState.h
//  Athena
//
//  Created by Skylar on 2019/10/26.
//  Copyright © 2019 Theresa. All rights reserved.
//

#ifndef SCPlayerState_h
#define SCPlayerState_h

typedef NS_ENUM(NSUInteger, SCPlayerState) {
    SCPlayerStateOrigin = 0,
    SCPlayerStatePlaying,
    SCPlayerStatePaused,
    SCPlayerStateClosed
};

@protocol ControlableProtocol <NSObject>



@end

#endif /* SCPlayerState_h */
