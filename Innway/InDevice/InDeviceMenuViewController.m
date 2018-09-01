//
//  InDeviceMenuViewController.m
//  Innway
//
//  Created by danly on 2018/8/5.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InDeviceMenuViewController.h"
#define InDeviceMenuCellReuseIdentifier @"InDeviceMenuCell"
#import "DLCloudDeviceManager.h"
#import "InDeviceListViewController.h"

@interface InDeviceMenuViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSDictionary *cloudDeviceList;

@end

@implementation InDeviceMenuViewController

+ (instancetype)menuViewController {
    InDeviceMenuViewController *menuVC = [[InDeviceMenuViewController alloc] init];
    menuVC.tableView.backgroundColor = [UIColor redColor];
    return menuVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:InDeviceMenuCellReuseIdentifier];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOnlineChange:) name:DeviceOnlineChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.cloudDeviceList = [DLCloudDeviceManager sharedInstance].cloudDeviceList;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceOnlineChangeNotification object:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cloudDeviceList.allKeys.count + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.cloudDeviceList.count) {
        return 50;
    }
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:InDeviceMenuCellReuseIdentifier];
    if (indexPath.row == self.cloudDeviceList.allKeys.count) {
        cell.imageView.image = [UIImage imageNamed:@"icon_add_device"];
        cell.textLabel.text = @"添加设备";
    }
    else {
        NSString *identify = self.cloudDeviceList.allKeys[indexPath.row];
        DLDevice *device = self.cloudDeviceList[identify];
        cell.imageView.image = [UIImage imageNamed:@"deviceMenu"];
        cell.textLabel.text = device.deviceName;
        if (device.online) {
            cell.textLabel.textColor = [UIColor blackColor];
        }
        else {
            cell.textLabel.textColor = [UIColor grayColor];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row == self.cloudDeviceList.allKeys.count) {
        NSLog(@"self.parentViewController = %@", self.parentViewController);
        if (self.parentViewController.navigationController.viewControllers.lastObject == self.parentViewController) {
             if(self.parentViewController.navigationController.viewControllers.count >= 2) {
                UIViewController *vc = self.parentViewController.navigationController.viewControllers[1];
                if ([vc isKindOfClass:[InDeviceListViewController class]]) {
                    [self.parentViewController.navigationController popToViewController:vc animated:YES];
                }
            }
        }
        
    }
    else {
        NSString *mac = self.cloudDeviceList.allKeys[indexPath.row];
        DLDevice *device = self.cloudDeviceList[mac];
        if (self.delegate) {
            [self.delegate menuViewController:self didSelectedDevice:device];
        }
    }
}

- (void)deviceOnlineChange:(NSNotification *)noti {
    [self.tableView reloadData];
}

@end
