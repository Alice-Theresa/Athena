//
//  AudioDecodeViewController.m
//  Athena
//
//  Created by Theresa on 2018/9/30.
//  Copyright © 2018年 Theresa. All rights reserved.
//

#import "AudioDecodeViewController.h"
#import "AudioSoftDecoder.h"
#import "AudioPlayerManager.h"

@interface AudioDecodeViewController () <AudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic, strong) AudioSoftDecoder *decoder;

@end

@implementation AudioDecodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[AudioPlayerManager shared] settingMode];
    
}

- (IBAction)start:(id)sender {
    self.playButton.hidden = YES;
    self.decoder = [[AudioSoftDecoder alloc] init];
    self.decoder.delegate = self;
    [self.decoder play];
}

- (void)onPlayToEnd:(AudioSoftDecoder *)decoder {
    self.decoder = nil;
    self.playButton.hidden = NO;
}

@end
