//
//  SCPlayerControlView.m
//  Athena
//
//  Created by Theresa on 2019/01/21.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCPlayerControlView.h"

@implementation SCPlayerControlView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
        [self defineLayout];
    }
    return self;
}

- (void)hideAll:(BOOL)hide {
    if (hide) {
        self.backButton.hidden = YES;
        self.actionButton.hidden = YES;
        self.timeLabel.hidden = YES;
        self.progressSlide.hidden = YES;
    } else {
        self.backButton.hidden = NO;
        self.actionButton.hidden = NO;
        self.timeLabel.hidden = NO;
        self.progressSlide.hidden = NO;
    }
}

- (void)settingPlay {
    [self.actionButton setTitle:@"暂停" forState:UIControlStateNormal];
}

- (void)settingPause {
    [self.actionButton setTitle:@"播放" forState:UIControlStateNormal];
}

- (void)setup {
    [self addSubview:self.backButton];
    [self addSubview:self.actionButton];
    [self addSubview:self.timeLabel];
    [self addSubview:self.progressSlide];
}

- (void)defineLayout {
    self.backButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressSlide.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.backButton
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeading
                                                    multiplier:1
                                                      constant:20]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.backButton
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1
                                                      constant:20]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.actionButton
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeading
                                                    multiplier:1
                                                      constant:20]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.actionButton
                                                     attribute:NSLayoutAttributeTrailing
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.timeLabel
                                                     attribute:NSLayoutAttributeLeading
                                                    multiplier:1
                                                      constant:-10]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.timeLabel
                                                     attribute:NSLayoutAttributeTrailing
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.progressSlide
                                                     attribute:NSLayoutAttributeLeading
                                                    multiplier:1
                                                      constant:-10]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressSlide
                                                     attribute:NSLayoutAttributeTrailing
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTrailing
                                                    multiplier:1
                                                      constant:-20]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.timeLabel
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1
                                                      constant:100]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.actionButton
                                                     attribute:NSLayoutAttributeBottom
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1
                                                      constant:-20]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.timeLabel
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.actionButton
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressSlide
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.actionButton
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];
    
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_backButton setTitle:@"Back" forState:UIControlStateNormal];
        
    }
    return _backButton;
}

- (UIButton *)actionButton {
    if (!_actionButton) {
        _actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_actionButton setTitle:@"暂停" forState:UIControlStateNormal];
    }
    return _actionButton;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.text = @"00:00:00/00:00:00";
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.font = [UIFont systemFontOfSize:10];
    }
    return _timeLabel;
}

- (UISlider *)progressSlide {
    if (!_progressSlide) {
        _progressSlide = [[UISlider alloc] init];
        _progressSlide.value = 0;
    }
    return _progressSlide;
}

@end
