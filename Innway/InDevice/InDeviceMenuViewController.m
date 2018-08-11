//
//  InDeviceMenuViewController.m
//  Innway
//
//  Created by danly on 2018/8/5.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InDeviceMenuViewController.h"
#define InDeviceMenuCellReuseIdentifier @"InDeviceMenuCell"

@interface InDeviceMenuViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray *deviceList;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation InDeviceMenuViewController

+ (instancetype)menuViewControllerWithDeviceList:(NSArray *)deviceList {
    InDeviceMenuViewController *menuVC = [[InDeviceMenuViewController alloc] init];
    menuVC.deviceList = deviceList;
    menuVC.tableView.backgroundColor = [UIColor redColor];
    return menuVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:InDeviceMenuCellReuseIdentifier];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.deviceList.count + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.deviceList.count) {
        return 50;
    }
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:InDeviceMenuCellReuseIdentifier];
    if (indexPath.row == self.deviceList.count) {
        cell.imageView.image = [UIImage imageNamed:@"icon_add_device"];
        cell.textLabel.text = @"添加设备";
    }
    else {
        cell.imageView.image = [UIImage imageNamed:@"deviceMenu"];
        cell.textLabel.text = @"INNWAY CARD";
    }
    return cell;
}

@end
