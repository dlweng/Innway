//
//  InDeviceListViewController.m
//  Innway
//
//  Created by danly on 2018/8/4.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InDeviceListViewController.h"
#import "InDeviceListCell.h"
#import "InControlDeviceViewController.h"

#define InDeviceListCellReuseIdentifier @"InDeviceListCell"

@interface InDeviceListViewController ()

@end

@implementation InDeviceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1];
    [self setUpNarBar];
}

- (void)setUpNarBar {
    self.navigationItem.title = @"设备列表";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    InDeviceListCell *cell = [tableView dequeueReusableCellWithIdentifier:InDeviceListCellReuseIdentifier];
    if (cell == nil) {
        UINib *nib = [UINib nibWithNibName:NSStringFromClass([InDeviceListCell class]) bundle:nil];
        [self.tableView registerNib:nib forCellReuseIdentifier:InDeviceListCellReuseIdentifier];
        cell = [tableView dequeueReusableCellWithIdentifier:InDeviceListCellReuseIdentifier];
    }
    cell.imageName = @"ic_launcher";
    cell.deviceName = @"INNWAY WARD";
    cell.deviceID = @"88:00:12:32";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    InControlDeviceViewController *controlDeviceVC = [[InControlDeviceViewController alloc] init];
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController pushViewController:controlDeviceVC animated:YES];
    }
    
}


@end
