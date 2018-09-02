//
//  InDeviceMenuViewController.m
//  Innway
//
//  Created by danly on 2018/8/5.
//  Copyright © 2018年 innwaytech. All rights reserved.
//
#define InDeviceMenuCell1ReuseIdentifier @"InDeviceMenuCell1"
#define InDeviceMenuCell2ReuseIdentifier @"InDeviceMenuCell2"

#import "InDeviceMenuViewController.h"
#import "DLCloudDeviceManager.h"
#import "InDeviceListViewController.h"
#import "InDeviceMenuCell1.h"
#import "InDeviceMenuCell2.h"
#import "InCommon.h"

@interface InDeviceMenuViewController ()<UITableViewDelegate, UITableViewDataSource, InDeviceMenuCell1Delegate>

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
    [self.tableView registerNib:[UINib nibWithNibName:@"InDeviceMenuCell1" bundle:nil] forCellReuseIdentifier:InDeviceMenuCell1ReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"InDeviceMenuCell2" bundle:nil] forCellReuseIdentifier:InDeviceMenuCell2ReuseIdentifier];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOnlineChange:) name:DeviceOnlineChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceRSSIChange:) name:DeviceRSSIChangeNotification object:nil];
    self.view.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.cloudDeviceList = [DLCloudDeviceManager sharedInstance].cloudDeviceList;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceOnlineChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceRSSIChangeNotification object:nil];
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
    if (indexPath.row == self.cloudDeviceList.allKeys.count) {
        InDeviceMenuCell2 *cell = [tableView dequeueReusableCellWithIdentifier:InDeviceMenuCell2ReuseIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        return cell;
    }
    else {
        InDeviceMenuCell1 *cell = [tableView dequeueReusableCellWithIdentifier:InDeviceMenuCell1ReuseIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        NSString *identify = self.cloudDeviceList.allKeys[indexPath.row];
        DLDevice *device = self.cloudDeviceList[identify];
        cell.iconView.image = [UIImage imageNamed:[[InCommon sharedInstance] getImageName:device.rssi]];
        cell.titleLabel.text = device.deviceName;
        cell.device = device;
        cell.delegate = self;
        return cell;
    }
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

- (void)deviceMenuCellSettingBtnDidClick:(InDeviceMenuCell1 *)cell {
    if ([self.delegate respondsToSelector:@selector(deviceSettingBtnDidClick:)]) {
        [self.delegate deviceSettingBtnDidClick:cell.device];
    }
}

- (void)deviceRSSIChange:(NSNotification *)noti {
    [self.tableView reloadData];
}

@end
