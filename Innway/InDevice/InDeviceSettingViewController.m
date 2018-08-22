//
//  InDeviceSettingViewController.m
//  Innway
//
//  Created by danly on 2018/8/5.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InDeviceSettingViewController.h"
#import "InAlertTableViewController.h"
#import "InAlertTool.h"
#import "DLCloudDeviceManager.h"
#import "InDeviceListViewController.h"
#define InDeviceSettingCellReuseIdentifier @"InDeviceSettingCell"

@interface InDeviceSettingViewController ()<UITableViewDataSource, UITableViewDelegate, DLDeviceDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *deleteDeviceBtn;
@property (nonatomic, strong) UISwitch *disconnectAlertBtn;
@property (nonatomic, strong) UISwitch *reconnectTipBtn;

@property (nonatomic, assign) NSNumber *phoneAlertMusic;

@end

@implementation InDeviceSettingViewController

+ (instancetype)deviceSettingViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"InDeviceSettingViewController" bundle:nil];
    InDeviceSettingViewController *deviceSettingVC = sb.instantiateInitialViewController;
    return deviceSettingVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"设备详情";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    
    self.disconnectAlertBtn = [[UISwitch alloc] init];
    [self.disconnectAlertBtn addTarget:self action:@selector(disconnectAlertBtnDidClick:) forControlEvents:UIControlEventValueChanged];
    self.reconnectTipBtn = [[UISwitch alloc] init];
    [self.reconnectTipBtn addTarget:self action:@selector(reconnectTipBtnDidClick:) forControlEvents:UIControlEventValueChanged];
    
    self.deleteDeviceBtn.layer.masksToBounds = YES;
    self.deleteDeviceBtn.layer.cornerRadius = 10;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView setContentOffset:CGPointZero animated:NO];
    });
    self.device.delegate = self;
    
    self.phoneAlertMusic = [[NSUserDefaults standardUserDefaults] objectForKey:PhoneAlertMusicKey];
    NSLog(@"手机警报声音: %zd", self.phoneAlertMusic.integerValue);
    if (!self.phoneAlertMusic) {
        self.phoneAlertMusic = @(1);
    }
    [self.tableView reloadData];
}

- (IBAction)deleteDeviceBtnDidClick {
    [InAlertTool showHUDAddedTo:self.view tips:@"正在删除设备，请稍候！" tag:1 animated:YES];
    [[DLCloudDeviceManager sharedInstance] deleteDevice:self.device.mac completion:^(DLCloudDeviceManager *manager, NSError *error) {
        [InAlertTool hideHUDForView:self.view tag:1];
        if (error) {
            [InAlertTool showAlertWithTip:@"设备删除失败"];
        }
        else {
            if(self.navigationController.viewControllers.count >= 2) {
                UIViewController *vc = self.navigationController.viewControllers[1];
                if ([vc isKindOfClass:[InDeviceListViewController class]]) {
                    [self.navigationController popToViewController:vc animated:YES];
                }
            }
        }
    }];
}

- (void)disconnectAlertBtnDidClick: (UISwitch *)btn {
    NSLog(@"断开警告被点击: %d", btn.isOn);
    [self.device setDisconnectAlert:btn.isOn reconnectAlert:self.reconnectTipBtn.isOn];
}

- (void)reconnectTipBtnDidClick:(UISwitch *)btn {
    NSLog(@"重连提示被点击: %d", btn.isOn);
    [self.device setDisconnectAlert:self.disconnectAlertBtn.isOn reconnectAlert:btn.isOn];
}

- (void)goBack {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
        case 1:
        case 2:
        case 3:
            return 2;
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"设备名称";
        case 1:
            return @"设备警报";
        case 2:
            return @"设备警报声音";
        case 3:
            return @"设备详情";
        default:
            return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:InDeviceSettingCellReuseIdentifier];
    switch (indexPath.section) {
        case 0:
        {
            cell.textLabel.text = self.device.deviceName;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case 1:
        {
            switch (indexPath.row) {
                case 0:
                {
                    cell.textLabel.text = @"断开警报";
                    cell.accessoryView = self.disconnectAlertBtn;
                    NSNumber *disconnectAlert = self.device.lastData[DisconnectAlertKey];
                    self.disconnectAlertBtn.on = disconnectAlert.boolValue;
                    break;
                }
                case 1:
                {
                    cell.textLabel.text = @"重连提示";
                    cell.accessoryView = self.reconnectTipBtn;
                    NSNumber *reconnectAlert = self.device.lastData[ReconnectAlertKey];
                    self.reconnectTipBtn.on = reconnectAlert.boolValue;
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 2:
        {
            switch (indexPath.row) {
                case 0:
                {
                    cell.textLabel.text = @"设备警报声音";
                    NSNumber *alertMusic = self.device.lastData[AlertMusicKey];
                    switch (alertMusic.integerValue) {
                        case 2:
                            cell.detailTextLabel.text = @"设备警报声二";
                            break;
                        case 3:
                            cell.detailTextLabel.text = @"设备警报声三";
                            break;
                        default:
                            cell.detailTextLabel.text = @"设备警报声一";
                            break;
                    }
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.textColor = [UIColor greenColor];
                    break;
                }
                case 1:
                {
                    cell.textLabel.text = @"手机警报声音";
                    switch (self.phoneAlertMusic.integerValue) {
                        case 2:
                            cell.detailTextLabel.text = @"手机警报声二";
                            break;
                        case 3:
                            cell.detailTextLabel.text = @"手机警报声三";
                            break;
                        default:
                            cell.detailTextLabel.text = @"手机警报声一";
                            break;
                    }
                    
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.textColor = [UIColor greenColor];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 3:
        {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"设备地址";
                    cell.detailTextLabel.text = self.device.mac;
                    cell.detailTextLabel.textColor = [UIColor darkGrayColor];
                    break;
                case 1:
                    cell.textLabel.text = @"固件版本";
                    cell.detailTextLabel.text = @"V1.0";
                    cell.detailTextLabel.textColor = [UIColor darkGrayColor];
                    break;
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    InAlertViewType alertType = InDeviceAlert;
    if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0:
                alertType = InDeviceAlert;
                break;
            case 1:
                alertType = InPhoneAlert;
                break;
            default:
                break;
        }
        InAlertTableViewController *alertVC = [[InAlertTableViewController alloc] initWithAlertType:alertType withDevice:self.device];
        if (self.navigationController.viewControllers.lastObject == self) {
            [self.navigationController pushViewController:alertVC animated:YES];
        }
    }
}

- (void)device:(DLDevice *)device didUpdateData:(NSDictionary *)data {
    [self.tableView reloadData];
}

@end
