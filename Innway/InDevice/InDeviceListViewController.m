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
#import "DLCloudDeviceManager.h"
#import "DLCentralManager.h"
#import "DLDevice.h"
#import "InAlertTool.h"
#import <SSPullToRefresh/SSPullToRefresh.h>


#define InDeviceListCellReuseIdentifier @"InDeviceListCell"

@interface InDeviceListViewController ()<SSPullToRefreshViewDelegate>
@property (nonatomic, strong) NSDictionary *knownPeripherals;

@property (strong, nonatomic) SSPullToRefreshView *pullToRefreshView;
@property (nonatomic, strong) DLCentralManager *centralManager;

@end

@implementation InDeviceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1];
    [self setUpNarBar];
    self.centralManager = [DLCentralManager sharedInstance];
    // 获取云端列表
    [[DLCloudDeviceManager sharedInstance] getHTTPCloudDeviceList];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self pullToRefreshViewDidStartLoading:self.pullToRefreshView];
    //每次进来先初始化界面
    self.knownPeripherals = [DLCentralManager sharedInstance].knownPeripherals;
    [self.tableView reloadData];
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.pullToRefreshView == nil) {
        self.pullToRefreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.tableView delegate:self];//下拉刷新
    }
    if ([[UIDevice currentDevice].systemVersion integerValue] < 11) { //ios11以下才需要
        self.pullToRefreshView.defaultContentInset = UIEdgeInsetsMake(64, 0, 64, 0);
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.pullToRefreshView finishLoading];
}

- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view {
    [self getPeripherals];
}

- (void)refreshTableView {
    if (self.pullToRefreshView.state == SSPullToRefreshViewStateLoading) {
        [self.pullToRefreshView finishLoadingAnimated:YES completion:^{
            self.knownPeripherals = self.centralManager.knownPeripherals;
            [self.tableView reloadData];
        }];
    } else {
        self.knownPeripherals = self.centralManager.knownPeripherals;
        [self.tableView reloadData];
    }
}

- (void)setUpNarBar {
    self.navigationItem.title = @"设备列表";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)getPeripherals {
    [[DLCentralManager sharedInstance] startScanDidDiscoverDeviceEvent:^(DLCentralManager *manager, CBPeripheral *peripheral, NSString *mac) {
        [self refreshTableView];
    } didEndDiscoverDeviceEvent:^(DLCentralManager *manager, NSMutableDictionary<NSString *,CBPeripheral *> *knownPeripherals) {
        self.knownPeripherals = knownPeripherals;
        [self refreshTableView];
    }];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.knownPeripherals.allKeys.count;
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
    NSString *key = self.knownPeripherals.allKeys[indexPath.row];
    CBPeripheral *peripheral = self.knownPeripherals[key];
    cell.imageName = @"ic_launcher";
    cell.deviceName = peripheral.name;
    cell.deviceID = key;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *mac = self.knownPeripherals.allKeys[indexPath.row];
    [InAlertTool showHUDAddedTo:self.view animated:YES];
    [[DLCloudDeviceManager sharedInstance] addDevice:mac completion:^(DLCloudDeviceManager *manager, DLDevice *device, NSError *error) {
        if (!error) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [InAlertTool showAlertAutoDisappear:@"添加设备成功" completion:^{
                InControlDeviceViewController *controlDeviceVC = [[InControlDeviceViewController alloc] init];
                controlDeviceVC.device = device;
                if (self.navigationController.viewControllers.lastObject == self) {
                    [self.navigationController pushViewController:controlDeviceVC animated:YES];
                }
            }];
        }
        else {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [InAlertTool showAlertAutoDisappear:@"添加设备失败"];
        }
    }];
    
}


- (NSDictionary *)knownPeripherals {
    if (!_knownPeripherals) {
        _knownPeripherals = [NSDictionary dictionary];
    }
    return _knownPeripherals;
}



@end
