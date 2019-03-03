//
//  InDeviceSettingViewController.m
//  Innway
//
//  Created by danly on 2018/8/5.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InCommon.h"
#import "InDeviceSettingViewController.h"
#import "DLCloudDeviceManager.h"
#import "InAddDeviceStartViewController.h"
#import "InDeviceSettingFooterView.h"
#import "InChangeDeviceNameView.h"
#import "InAlarmTypeSelectionView.h"
#define InDeviceSettingCellReuseIdentifier @"InDeviceSettingCell"

@interface InDeviceSettingViewController ()<UITableViewDataSource, UITableViewDelegate, DLDeviceDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *deleteDeviceBtn;
@property (nonatomic, strong) UISwitch *disconnectAlertBtn;
//@property (nonatomic, strong) UISwitch *reconnectTipBtn;

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
    self.navigationItem.title = @"Device settings";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    
    self.disconnectAlertBtn = [[UISwitch alloc] init];
    self.disconnectAlertBtn.onTintColor = [InCommon backgroundColor];
    [self.disconnectAlertBtn addTarget:self action:@selector(disconnectAlertBtnDidClick:) forControlEvents:UIControlEventValueChanged];
//    self.reconnectTipBtn = [[UISwitch alloc] init];
//    [self.reconnectTipBtn addTarget:self action:@selector(reconnectTipBtnDidClick:) forControlEvents:UIControlEventValueChanged];
    
    self.deleteDeviceBtn.layer.masksToBounds = YES;
    self.deleteDeviceBtn.layer.cornerRadius = 10;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView setContentOffset:CGPointZero animated:NO];
    });
    NSLog(@"手机警报声音: %zd", self.phoneAlertMusic.integerValue);
    if (!self.phoneAlertMusic) {
        self.phoneAlertMusic = @(1);
    }
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.device.delegate = self;
}

- (IBAction)deleteDeviceBtnDidClick {
    [InAlertView showAlertWithMessage:@"Unpair and delete device?" confirmHanler:^{
        [self deleteDevice];
    } cancleHanler:nil];
}

- (void)deleteDevice {
    [InAlertTool showHUDAddedTo:self.view animated:YES];
    [[DLCloudDeviceManager sharedInstance] deleteDevice:self.device.mac completion:^(DLCloudDeviceManager *manager, NSError *error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (error) {
            [InAlertView showAlertWithTitle:@"Information" message:error.localizedDescription confirmTitle:nil confirmHanler:nil];
        }
        else {
            if (manager.cloudDeviceList.count > 0) {
                if (self.navigationController.viewControllers.lastObject == self) {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
            else {
                // 没有设备了，跳转到添加界面
                if (self.navigationController.viewControllers.lastObject == self) {
                    NSArray *subViewController = self.navigationController.viewControllers;
                    if (subViewController.count > 3) {
                        InAddDeviceStartViewController *addDeviceStartVC = subViewController[2];
                        if ([addDeviceStartVC isKindOfClass:[InAddDeviceStartViewController class]]) {
                            [self.navigationController popToViewController:addDeviceStartVC animated:YES];
                        }
                    }
                }
            }
        }
    }];
}

- (void)disconnectAlertBtnDidClick: (UISwitch *)btn {
//    NSLog(@"断开警告被点击: %d", btn.isOn);
    [self.device setDisconnectAlert:btn.isOn reconnectAlert:NO];
}

//- (void)reconnectTipBtnDidClick:(UISwitch *)btn {
////    NSLog(@"重连提示被点击: %d", btn.isOn);
//    [self.device setDisconnectAlert:self.disconnectAlertBtn.isOn reconnectAlert:btn.isOn];
//}

- (void)saveNewDeviceName:(NSString *)newDeviceName {
    // 保存设备名称
    self.device.deviceName = newDeviceName;
    // 保存设备名称到本地
    [common saveDeviceName:self.device];
    // 上传新名称到云端
    NSDictionary* body = @{@"id":[NSString stringWithFormat:@"%zd", self.device.cloudID], @"NickName":newDeviceName, @"action":@"updateTrackerNickName"};
    [InCommon sendHttpMethod:@"POST" URLString:httpDomain body:body completionHandler:^(NSURLResponse *response, NSDictionary *responseObject, NSError * _Nullable error) {
        NSLog(@"修改设备名称结果:responseObject = %@, error = %@", responseObject, error);
    }];
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
        case 1:
            return 1;
        case 2:
        case 3:
            return 2;
        default:
            return 0;
    }
}

// 下面两个方法都必须设置，才能成功设置分组头的值
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Device Name";
        case 1:
            return @"Device Alert";
        case 2:
            return @"Alert Tone";
        case 3:
            return @"Device Details";
        default:
            return @"";
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *sectionName = @"";
    switch (section) {
        case 0:
            sectionName = @"    Device Name";
            break;
        case 1:
            sectionName = @"    Device Alert";
            break;
        case 2:
            sectionName = @"    Alert Tone";
            break;
        case 3:
            sectionName = @"    Device Details";
            break;
        default:
            break;
    }
    UILabel *label = [[UILabel alloc] init];
    label.text = sectionName;
    label.font = [UIFont systemFontOfSize:13.0];
    label.textColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1];
    return label;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 35;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:InDeviceSettingCellReuseIdentifier];
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.textColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
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
                    cell.textLabel.text = @"Separation Alert";
                    cell.accessoryView = self.disconnectAlertBtn;
                    NSNumber *disconnectAlert = self.device.lastData[DisconnectAlertKey];
                    self.disconnectAlertBtn.on = disconnectAlert.boolValue;
                    break;
                }
//                case 1:
//                {
//                    cell.textLabel.text = @"Reconnect prompt";
//                    cell.accessoryView = self.reconnectTipBtn;
//                    NSNumber *reconnectAlert = self.device.lastData[ReconnectAlertKey];
//                    self.reconnectTipBtn.on = reconnectAlert.boolValue;
//                    break;
//                }
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
                    cell.textLabel.text = @"Device Alert Tone";
                    NSNumber *alertMusic = self.device.lastData[AlertMusicKey];
                    switch (alertMusic.integerValue) {
                        case 2:
                            cell.detailTextLabel.text = @"Alert 2";
                            break;
                        case 3:
                            cell.detailTextLabel.text = @"Alert 3";
                            break;
                        default:
                            cell.detailTextLabel.text = @"Alert 1";
                            break;
                    }
                    break;
                }
                case 1:
                {
                    self.phoneAlertMusic = [[NSUserDefaults standardUserDefaults] objectForKey:PhoneAlertMusicKey];
                    cell.textLabel.text = @"Phone Alert Tone";
                    switch (self.phoneAlertMusic.integerValue) {
                        case 2:
                            cell.detailTextLabel.text = @"Alert 2";
                            break;
                        case 3:
                            cell.detailTextLabel.text = @"Alert 3";
                            break;
                        default:
                            cell.detailTextLabel.text = @"Alert 1";
                            break;
                    }
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
                    cell.textLabel.text = @"Device Address";
                    cell.detailTextLabel.text = self.device.mac;
                    break;
                case 1:
                    cell.textLabel.text = @"Firmware";
                    cell.detailTextLabel.text = self.device.firmware;
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
    InAlarmType alertType = InDeviceAlert;
    NSString *title = @"Select device alert tone";
    if (indexPath.section == 0 && indexPath.row == 0) {
        [InChangeDeviceNameView showChangeDeviceNameView:self.device.deviceName confirmHandle:^(NSString * _Nonnull newDeviceName) {
            NSLog(@"新设备名称: %@", newDeviceName);
            if (newDeviceName.length > 0) {
                [self saveNewDeviceName:newDeviceName];
                [self.tableView reloadData];
            }
            else {
                [InAlertView showAlertWithTitle:@"Information" message:@"Please enter device name" confirmTitle:nil confirmHanler:nil];
            }
        }];
        return;
    }
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
        // 获取当前的报警声音
        NSInteger currentAlarmVoice = 0;
        switch (alertType) {
            case InPhoneAlert:
            {
                NSNumber *phoneAlertMusic = [[NSUserDefaults standardUserDefaults] objectForKey:PhoneAlertMusicKey];
                if (phoneAlertMusic) {
                    currentAlarmVoice = phoneAlertMusic.integerValue - 1;
                }
                else {
                    currentAlarmVoice = 0;
                }
                title = @"Select phone alert tone";
                break;
            }
            case InDeviceAlert:
            {
                NSNumber *alertMusic = self.device.lastData[AlertMusicKey];
                currentAlarmVoice = alertMusic.integerValue - 1;
                title = @"Select device alert tone";
                break;
            }
            default:
                break;
        }
        // 弹出选择框
        [InAlarmTypeSelectionView showAlarmTypeSelectionView:alertType title:title currentAlarmVoice:currentAlarmVoice confirmHanler:^(NSInteger newAlertVoice) {
            switch (alertType) {
                case InPhoneAlert:
                {
                    [[NSUserDefaults standardUserDefaults] setValue:@(newAlertVoice) forKey:PhoneAlertMusicKey];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                    break;
                case InDeviceAlert:
                    [self.device selecteDiconnectAlertMusic:newAlertVoice];
                    break;
                default:
                    break;
            }
            [self.tableView reloadData];
        }];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 3) {
        InDeviceSettingFooterView *footerView = [[InDeviceSettingFooterView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 80)];
        [footerView.deleteBtn addTarget:self action:@selector(deleteDeviceBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
        return footerView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 3) {
        return 80;
    }
    return 0;
}

- (void)device:(DLDevice *)device didUpdateData:(NSDictionary *)data {
    [self.tableView reloadData];
}

@end
