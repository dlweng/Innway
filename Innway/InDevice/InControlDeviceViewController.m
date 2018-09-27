//
//  InControlDeviceViewController.m
//  Innway
//
//  Created by danly on 2018/8/4.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InControlDeviceViewController.h"
#import "InUserSettingViewController.h"
#import "InDeviceMenuViewController.h"
#import "InDeviceSettingViewController.h"
#import "DLCloudDeviceManager.h"
#import "InAnnotationView.h"
#import <MapKit/MapKit.h>
#import "InCommon.h"
#import "InLoginViewController.h"

@interface InControlDeviceViewController ()<DLDeviceDelegate, InDeviceMenuViewControllerDelegate, MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *controlBtnBottomGapContraint;
@property (weak, nonatomic) IBOutlet UIButton *controlDeviceBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topBodyViewTopConstraint;
@property (weak, nonatomic) IBOutlet UIView *topBodyView;
@property (nonatomic, weak) UIView *settingView;

@property (nonatomic, strong) UIBarButtonItem *settingImageBarButton;
@property (nonatomic, strong) UIBarButtonItem *SettingTitleBarButton;

@property (weak, nonatomic) IBOutlet UIView *deviceMenuView;
@property (weak, nonatomic) IBOutlet UIView *deviceMenuBackgroupView;

@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
// 存储掉线设备大头针的位置
@property (nonatomic, strong) NSMutableDictionary *deviceAnnotation;

@property (weak, nonatomic) IBOutlet UIButton *battery;

@property (weak, nonatomic) IBOutlet UIButton *deviceSettingBtn;
@property (weak, nonatomic) IBOutlet UIImageView *deviceImageView;
@property (weak, nonatomic) IBOutlet UIView *bottomBodyView;
@property (weak, nonatomic) IBOutlet UIView *backgroupView;


@end

@implementation InControlDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.topBodyViewTopConstraint.constant += 64;
    if ([UIScreen mainScreen].bounds.size.height == 812) { //iphonex
        //iphoneX底部和顶部需要多留20px空白
        self.controlBtnBottomGapContraint.constant += 20;
        self.topBodyViewTopConstraint.constant += 20;
    }
    
    // 设置按钮圆弧
    self.controlDeviceBtn.layer.masksToBounds = YES;
    self.controlDeviceBtn.layer.cornerRadius = 5;
    self.bottomBodyView.layer.masksToBounds = YES;
    self.bottomBodyView.layer.cornerRadius = 5;
    self.deviceMenuBackgroupView.layer.masksToBounds = YES;
    self.deviceMenuBackgroupView.layer.cornerRadius = 5;
    
    [self setupNarBar];
    [self addSettingView];
    [self addDeviceMenu];
    self.topBodyView.backgroundColor = [UIColor redColor];
    
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = NO;
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    self.deviceSettingBtn.transform = CGAffineTransformRotate(self.deviceSettingBtn.transform, M_PI * 0.5);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceRSSIChange:) name:DeviceRSSIChangeNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceRSSIChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.device.delegate = self;
    [self.device getDeviceInfo];
    [self updateAnnotation];
    [self updateUI];
}


- (void)addDeviceMenu {
    InDeviceMenuViewController *deviceMenuVC = [InDeviceMenuViewController menuViewController];
    deviceMenuVC.delegate = self;
    [self addChildViewController:deviceMenuVC];
    [self.deviceMenuBackgroupView addSubview:deviceMenuVC.view];
    deviceMenuVC.view.frame = self.deviceMenuBackgroupView.bounds;
    self.deviceMenuView.hidden = YES;
}

- (void)addSettingView {
    InUserSettingViewController *settingVC = [[InUserSettingViewController alloc] init];
    [self addChildViewController:settingVC];
    [self.view addSubview:settingVC.view];
    self.settingView = settingVC.view;
    CGFloat y = self.topBodyViewTopConstraint.constant;
    CGFloat width = self.view.frame.size.width * 0.85;
    CGFloat height = self.view.frame.size.height - y;
    CGFloat x = -width;
    settingVC.view.frame = CGRectMake(x, y, width, height);
    settingVC.leftGestureCompleted = ^(UIGestureRecognizer *gesture) {
            [self showSettingVC:NO];
    };
    settingVC.logoutUser = ^{
        if (self.navigationController.viewControllers.lastObject == self &&
            self.navigationController.viewControllers.count > 2) {
            UIViewController *loginVC = self.navigationController.viewControllers[1];
            if ([loginVC isKindOfClass:[InLoginViewController class]]) {
                NSLog(@"退出账户");
                [self.navigationController popToViewController:loginVC animated:YES];
//                [self.navigationController popToRootViewControllerAnimated:YES];
            }
            
        }
    };
    NSLog(@"settingView.frame = %@", [NSValue valueWithCGRect:self.settingView.frame]);
    NSLog(@"self.view.frame = %@", [NSValue valueWithCGRect:self.view.frame]);
    NSLog(@"bounds = %@", [NSValue valueWithCGRect:[UIScreen mainScreen].bounds]);
    self.settingView.hidden = YES;
}

- (void)showSettingVC: (BOOL)isShow {
    CGRect frame = self.settingView.frame;
    CGPoint origin = frame.origin;
    if (isShow) {
        //显示
        origin.x = 0;
        self.settingView.hidden = NO;
    }
    else {
        CGFloat width = frame.size.width;
        origin.x = -width;
    }
    frame.origin = origin;
    //动画显示
    [UIView animateWithDuration:0.35 animations:^{
        if (isShow) {
            self.navigationItem.leftBarButtonItem = self.SettingTitleBarButton;
        }
        else {
            self.navigationItem.leftBarButtonItem = self.settingImageBarButton;
        }
        self.settingView.frame = frame;
    } completion:^(BOOL finished) {
        if (!isShow) {
            self.settingView.hidden = YES;
        }
    }];
}

- (void)setupNarBar {
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"innwayLOGO"]];
    self.settingImageBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_setting"] style:UIBarButtonItemStylePlain target:self action:@selector(goToSettingVC)];
    //用户设置
    self.SettingTitleBarButton = [[UIBarButtonItem alloc] initWithTitle:@"用户设置" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.leftBarButtonItem = self.settingImageBarButton;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_menu"] style:UIBarButtonItemStylePlain target:self action:@selector(goToMenu)];
}

- (void)goToSettingVC {
    [self showSettingVC:YES];
    self.navigationItem.leftBarButtonItem = self.SettingTitleBarButton;
}

- (void)goToMenu {
    BOOL isshow = self.deviceMenuView.hidden;
    [UIView animateWithDuration:0.25 animations:^{
        self.deviceMenuView.hidden = !isshow;
        if (isshow) {
            self.bottomBodyView.hidden = YES;
        }
        else {
            self.bottomBodyView.hidden = NO;
        }
    }];
}

#pragma mark - Action
//控制设备
- (IBAction)controlDeviceBtnDidClick:(UIButton *)sender {
    NSLog(@"下发控制指令");
    [self.device searchDevice];
}

//进入更多界面
- (IBAction)more {
    NSLog(@"进入更多界面");
    if (self.navigationController.viewControllers.lastObject == self) {
        InDeviceSettingViewController *vc = [InDeviceSettingViewController deviceSettingViewController];
        vc.device = self.device;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (IBAction)toSwitchMapMode {
    NSLog(@"切换地图模式");
//    MKMapTypeStandard = 0,
//    MKMapTypeSatellite,
    if (self.mapView.mapType == MKMapTypeStandard) {
        self.mapView.mapType = MKMapTypeSatellite;
    }
    else {
        self.mapView.mapType = MKMapTypeStandard;
    }
}

- (IBAction)toLocation {
    NSLog(@"开始定位");
    [self.mapView setCenterCoordinate:self.mapView.userLocation.coordinate];
}

- (void)updateUI {
    //根据设备的信息界面
//    self.device.lastData
    self.deviceNameLabel.text = self.device.deviceName;
    self.deviceImageView.image = [UIImage imageNamed:[[InCommon sharedInstance] getImageName:self.device.rssi]];
    if (self.device.data.count > 0) {
        NSString *batteryImageName = @"10";
        NSInteger battery = [self.device.data integerValueForKey:ElectricKey defaultValue:0];
        if (battery > 90) {
            batteryImageName = @"100";
        }
        else if (battery > 80) {
            batteryImageName = @"90";
        }
        else if (battery > 70) {
            batteryImageName = @"80";
        }
        else if (battery > 60) {
            batteryImageName = @"70";
        }
        else if (battery > 50) {
            batteryImageName = @"60";
        }
        else if (battery > 40) {
            batteryImageName = @"50";
        }
        else if (battery > 30) {
            batteryImageName = @"40";
        }
        else if (battery > 20) {
            batteryImageName = @"30";
        }
        else if (battery > 10) {
            batteryImageName = @"20";
        } else {
            batteryImageName = @"10";
        }
        [self.battery setBackgroundImage:[UIImage imageNamed:batteryImageName] forState:UIControlStateNormal];
        [self.battery setTitle:[NSString stringWithFormat:@"%@%%", batteryImageName] forState:UIControlStateNormal];
        if (battery > 20) {
            [self.battery setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        }
        else {
            [self.battery setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
    }
}

- (void)device:(DLDevice *)device didUpdateData:(NSDictionary *)data{
    if (device == self.device) {
        [self updateUI];
    }
}

- (void)menuViewController:(InDeviceMenuViewController *)menuVC didSelectedDevice:(DLDevice *)device {
    if (!device.online) {
        if (device.rssi.integerValue > -100) {
            [InAlertTool showHUDAddedTo:self.view animated:YES];
            [[DLCloudDeviceManager sharedInstance] addDevice:device.mac completion:^(DLCloudDeviceManager *manager, DLDevice *newdevice, NSError *error) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                if ([newdevice.mac isEqualToString:device.mac]) {
                    if (error) {
                        if (error.code < -1000) {
                            [InAlertTool showAlertAutoDisappear:@"网络连接异常"];
                            return ;
                        }
                        [InAlertTool showAlertAutoDisappear:@"建立连接失败"];
                        return ;
                    }
                    [self goToMenu];
                    [self updateDevice:newdevice];
                }
            }];
        }
        return;
    }
    [self goToMenu];
    if (device != self.device) {
        [self updateDevice:device];
    }
}

- (void)updateDevice:(DLDevice *)device {
    self.device.delegate = nil;
    self.device = device;
    self.device.delegate = self;
    [self.device getDeviceInfo];
    [self updateAnnotation];
    [self updateUI];
    [self toLocation];
}

- (void)deviceSettingBtnDidClick:(DLDevice *)device {
    if (!device.online) {
        return;
    }
    [self menuViewController:nil didSelectedDevice:device];
    [self more];
}

#pragma mark - Map
-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    NSLog(@"地图用户位置更新, %f, %f", userLocation.coordinate.latitude, userLocation.coordinate.longitude);
    [InCommon sharedInstance].currentLocation = userLocation.coordinate;
}

// 画自定义大头针的方法
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[InAnnotation class]]) {
        NSString *reuseID = @"InAnnotationView";
        InAnnotationView *annotationView = (InAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseID];
        if (annotationView == nil) {
            annotationView = [[InAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseID];
            
        }
        return annotationView;
    }
    return nil;
}

- (void)updateAnnotation{
    NSMutableDictionary *cloudDeviceList = [DLCloudDeviceManager sharedInstance].cloudDeviceList;
    for (NSString *mac in cloudDeviceList.allKeys) {
        DLDevice *device = cloudDeviceList[mac];
        InAnnotation *annotation = [self.deviceAnnotation objectForKey:mac];
        if (device.online && annotation) {
            // 设备在线，但是存在大头针，删除大头针
            [self.deviceAnnotation removeObjectForKey:mac];
            [self.mapView removeAnnotation:annotation];
        }
        else if (!device.online && !annotation) {
            // 设备不在线，且不存在大头针，需要增加
            annotation = [[InAnnotation alloc] init];
            annotation.coordinate = device.coordinate;
            annotation.title = device.deviceName;
            [self.deviceAnnotation setObject:annotation forKey:mac];
            [self.mapView addAnnotation:annotation];
        }
    }
}

- (void)deviceRSSIChange:(NSNotification *)noti {
    DLDevice *device = noti.object;
    if (device.mac == self.device.mac) {
        [self updateUI];
    }
}

@end
