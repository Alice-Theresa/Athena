//
//  MainViewController.m
//  Athena
//
//  Created by Theresa on 2017/10/18.
//  Copyright © 2017年 Theresa. All rights reserved.
//

#import "MainViewController.h"
#import "MainViewModel.h"
#import "MainModel.h"

@interface MainViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MainViewModel *viewModel;

@end

static NSString *cellIdentifier = @"cellIdentifier";

@implementation MainViewController

- (instancetype)init {
    if (self = [super init]) {
        _viewModel = [[MainViewModel alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MainModel *model = self.viewModel.codecNames[indexPath.row];
    UIViewController *vc = [[NSClassFromString(model.vcName) alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    MainModel *model = self.viewModel.codecNames[indexPath.row];
    cell.textLabel.text = model.codecName;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.codecNames.count;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:cellIdentifier];
    }
    return _tableView;
}

@end
