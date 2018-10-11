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

#define coverViewAlpha 0.85

@interface InControlDeviceViewController ()<DLDeviceDelegate, InDeviceMenuViewControllerDelegate, MKMapViewDelegate, InUserSettingViewControllerDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *controlBtnBottomGapContraint;
@property (weak, nonatomic) IBOutlet UIButton *controlDeviceBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topBodyViewTopConstraint;
@property (weak, nonatomic) IBOutlet UIView *topBodyView;
@property (nonatomic, weak) UIView *settingView;
@property (nonatomic, weak) UIViewController *settingVC;

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
@property (nonatomic, strong)InDeviceMenuViewController *deviceMenuVC;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deviceMenuHeightConstraint;
@property (nonatomic, weak) UIView *coverView;

@end

@implementation InControlDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 自动连接云端设备
    [[DLCloudDeviceManager sharedInstance] autoConnectCloudDevice];
    if (!self.device) {
        [self sortDeviceList];
    }
    
    // 界面调整
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
    
    [self setupNarBar];
    [self addDeviceMenu];
    [self addSettingView];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceChangeOnline:) name:DeviceOnlineChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceOnlineChangeNotification object:nil];
}


- (void)addDeviceMenu {
    self.deviceMenuVC = [InDeviceMenuViewController menuViewControllerWithCloudList:[self sortDeviceList]];
    self.deviceMenuVC.delegate = self;
    [self addChildViewController:self.deviceMenuVC];
    [self.deviceMenuView addSubview:self.deviceMenuVC.view];
    self.deviceMenuVC.view.frame = self.deviceMenuView.bounds;
    [self menuViewController:self.deviceMenuVC moveDown:MAXFLOAT];
}

- (void)addSettingView {
    // 添加覆盖层
    UIView *view = [[UIView alloc] init];
    [self.navigationController.view.superview addSubview:view];
    view.frame = [UIScreen mainScreen].bounds;
    view.backgroundColor = [UIColor blackColor];
    [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideCoverView)]];
    view.alpha = 0;
    self.coverView = view;
    
    // 添加用户设置界面
    InUserSettingViewController *settingVC = [[InUserSettingViewController alloc] init];
    [self.navigationController addChildViewController:settingVC];
    [self.navigationController.view.superview addSubview:settingVC.view];
    self.settingView = settingVC.view;
    CGFloat x = 0;
    CGFloat y = -44;
    CGFloat width = [UIScreen mainScreen].bounds.size.width * 0.85;
    CGFloat height = [UIScreen mainScreen].bounds.size.height-y;
    settingVC.view.frame = CGRectMake(x, y, width, height);
    settingVC.delegate = self;
    self.settingVC = settingVC;
    __block UIViewController *weakSettingVC = settingVC;
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
    // 隐藏 settingView
    [self hideSettingView];
}

- (void)hideSettingView {
    [self settingViewController:self.settingVC touchEnd:CGPointMake(MAXFLOAT, 0)];
}


- (void)setupNarBar {
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"innwayLOGO"]];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"user"] style:UIBarButtonItemStylePlain target:self action:@selector(goToSettingVC)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_menu"] style:UIBarButtonItemStylePlain target:self action:@selector(goToMenu)];
}

- (void)goToSettingVC {
    self.coverView.alpha = coverViewAlpha; // 显示覆盖层
    [self settingViewController:self.settingVC touchEnd:CGPointMake(-MAXFLOAT, 0)];
}

- (void)goToMenu {
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
    NSString *deviceName = self.device.deviceName;
    deviceName = @"Lily";
    [self.controlDeviceBtn setTitle:[NSString stringWithFormat:@"Ring Innway %@", deviceName] forState:UIControlStateNormal];
    [self.deviceMenuVC reloadView:nil];
    [self updateAnnotation];
}

- (void)device:(DLDevice *)device didUpdateData:(NSDictionary *)data{
    if (device == self.device) {
        [self updateUI];
    }
}

#pragma menuViewDelegate
- (void)menuViewController:(InDeviceMenuViewController *)menuVC didSelectedDevice:(DLDevice *)device {
    [self menuViewController:self.deviceMenuVC moveDown:MAXFLOAT];
    if (device != self.device) {
        [self updateDevice:device];
    }
}

- (void)menuViewController:(InDeviceMenuViewController *)menuVC moveDown:(CGFloat)down {
    if (down > 0) {
        //往下
        CGFloat minHeight = 190;
        if ([DLCloudDeviceManager sharedInstance].cloudDeviceList.count > 1) {
            minHeight = 142;
        }
        CGFloat maxMenuHeight = [UIScreen mainScreen].bounds.size.height * 0.5;
        if (maxMenuHeight + self.deviceMenuHeightConstraint.constant - down < minHeight) {
            down = maxMenuHeight + self.deviceMenuHeightConstraint.constant - minHeight;
            menuVC.down = NO;
        }
    }
    else {
        // 往上
        if (self.deviceMenuHeightConstraint.constant - down > 0) {
            down = self.deviceMenuHeightConstraint.constant;
            menuVC.down = YES;
        }
    }
    self.deviceMenuHeightConstraint.constant -= down;
}

#pragma mark - settingVCDelegate
- (void)settingViewController:(InUserSettingViewController *)settingVC touchMove:(CGPoint)move {
    CGFloat width = settingVC.view.bounds.size.width;
    CGRect frame = settingVC.view.frame;
    CGFloat x = frame.origin.x - move.x;
    if (x >= 0) {
        frame.origin.x = 0;
    }
    else if (x <= -width){
        frame.origin.x = -width;
    }
    else {
        frame.origin.x = x;
    }
    CGFloat alpha = (width + frame.origin.x) / width * coverViewAlpha;
    [UIView animateWithDuration:0.05 animations:^{
        settingVC.view.frame = frame;
        self.coverView.alpha = alpha;
    }];
}

- (void)settingViewController:(InUserSettingViewController *)settingVC touchEnd:(CGPoint)move {
    CGFloat width = settingVC.view.bounds.size.width;
    CGRect frame = settingVC.view.frame;
    CGFloat x = frame.origin.x - move.x;
    if (x >= -0.5 * width) {
        frame.origin.x = 0;
    }
    else if (x <= -0.5 * width){
        frame.origin.x = -width;
    }
    CGFloat alpha = (width + frame.origin.x) / width * coverViewAlpha;
    [UIView animateWithDuration:0.25 animations:^{
        settingVC.view.frame = frame;
        self.coverView.alpha = alpha;
    }];
}

- (void)updateDevice:(DLDevice *)device {
    self.device.delegate = nil;
    self.device = device;
    self.device.delegate = self;
    [self.deviceMenuVC reloadView:[self sortDeviceList]];
    [self.device getDeviceInfo];
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

- (void)deviceChangeOnline:(NSNotification *)notification {
    NSLog(@"接收到设备状态改变的通知: %@", notification.object);
    [self updateAnnotation];
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

- (NSArray *)sortDeviceList {
    NSDictionary *cloudList = [DLCloudDeviceManager sharedInstance].cloudDeviceList;
    if (cloudList.count == 0) {
        return @[];
    }
    if (!self.device) {
        for (NSString *mac in cloudList.allKeys) {
            //第一个连接的设备是赋值为self.device
            DLDevice *device = cloudList[mac];
            if (device.connected) {
                self.device = device;
                break;
            }
        }
        
    }
    if (!self.device) {
        //全部设备都没有连接，将第一个设备设置为self.device
        self.device = cloudList[cloudList.allKeys[0]];
    }
    NSMutableArray *connectList = [NSMutableArray array];
    [connectList addObject:self.device];
    NSMutableArray *disConnectList = [NSMutableArray array];
    // 先将已经连接的筛选出来
    for (NSString *mac in cloudList.allKeys) {
        DLDevice *device = cloudList[mac];
        if (device != self.device) {
            if (device.connected) {
                [connectList addObject:device];
            }
            else {
                [disConnectList addObject:device];
            }
        }
    }
    [connectList addObjectsFromArray:disConnectList];
    return [connectList copy];
}

#pragma mark - Properity
- (NSMutableDictionary *)deviceAnnotation {
    if (!_deviceAnnotation) {
        _deviceAnnotation = [NSMutableDictionary dictionary];
    }
    return _deviceAnnotation;
}

- (void)hideCoverView {
    [self hideSettingView];
}

@end
