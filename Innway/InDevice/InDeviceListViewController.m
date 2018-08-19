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


#define InDeviceListCellReuseIdentifier @"InDeviceListCell"

@interface InDeviceListViewController ()
@property (nonatomic, strong) NSDictionary *knownPeripherals;

@end

@implementation InDeviceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1];
    [self setUpNarBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
    [[DLCentralManager sharedInstance] startScanCompletion:^(DLCentralManager *manager, NSMutableDictionary<NSString *,CBPeripheral *> *knownPeripherals) {
        self.knownPeripherals = knownPeripherals;
        [self.tableView reloadData];
    }];
    //每次进来先初始化界面
    self.knownPeripherals = [DLCentralManager sharedInstance].knownPeripherals;
    [self.tableView reloadData];
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
    cell.deviceID = peripheral.identifier.UUIDString;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *identify = self.knownPeripherals.allKeys[indexPath.row];
    [[DLCloudDeviceManager sharedInstance] addDevice:identify completion:^(DLCloudDeviceManager *manager, DLDevice *device, NSError *error) {
        if (!error) {
            [InAlertTool showAlertAutoDisappear:@"添加设备成功" completion:^{
                InControlDeviceViewController *controlDeviceVC = [[InControlDeviceViewController alloc] init];
                controlDeviceVC.device = device;
                if (self.navigationController.viewControllers.lastObject == self) {
                    [self.navigationController pushViewController:controlDeviceVC animated:YES];
                }
            }];
        }
        else {
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
