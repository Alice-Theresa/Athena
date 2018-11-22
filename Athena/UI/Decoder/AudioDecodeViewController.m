//
//  AudioDecodeViewController.m
//  Athena
//
//  Created by Theresa on 2018/9/30.
//  Copyright © 2018年 Theresa. All rights reserved.
//

#import "AudioDecodeViewController.h"
#import "AudioDecoder.h"
#import "AudioPlayerManager.h"

@interface AudioDecodeViewController () <AudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic, strong) AudioDecoder *decoder;

@end

@implementation AudioDecodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[AudioPlayerManager shared] settingMode];
    
}

- (IBAction)start:(id)sender {
    self.playButton.hidden = YES;
    self.decoder = [[AudioDecoder alloc] init];
    self.decoder.delegate = self;
    [self.decoder play];
}

- (void)onPlayToEnd:(AudioDecoder *)decoder {
    self.decoder = nil;
    self.playButton.hidden = NO;
}

@end
