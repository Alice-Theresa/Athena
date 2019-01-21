//
//  SCPlayerControlView.h
//  Athena
//
//  Created by Theresa on 2019/01/21.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCPlayerControlView : UIView

@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UISlider *progressSlide;

- (void)hideAll:(BOOL)hide;
- (void)settingPause;
- (void)settingPlay;

@end

NS_ASSUME_NONNULL_END
