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
#import "InAddDeviceStartViewController.h"

#define coverViewAlpha 0.85  // 覆盖层的透明度

@interface InControlDeviceViewController ()<DLDeviceDelegate, InDeviceMenuViewControllerDelegate, MKMapViewDelegate, InUserSettingViewControllerDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topBodyViewTopConstraint;
@property (weak, nonatomic) IBOutlet UIView *topBodyView;
@property (weak, nonatomic) IBOutlet UIButton *controlDeviceBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *controlBtnBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomBtnViewHeightConstaint;


// 设置界面
@property (nonatomic, weak) UIView *settingView;
@property (nonatomic, weak) UIViewController *settingVC;

// 设备列表
@property (weak, nonatomic) IBOutlet UIView *deviceListBodyView;
@property (weak, nonatomic) IBOutlet UIView *deviceListBackgroupView;
@property (nonatomic, strong)InDeviceMenuViewController *deviceListVC;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deviceListBodyHeightConstraint;

// 地图
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
// 存储掉线设备大头针的位置
@property (nonatomic, strong) NSMutableDictionary *deviceAnnotation;

// 显示设置界面的透明覆盖层
@property (nonatomic, weak) UIView *coverView;

@end

@implementation InControlDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 自动连接云端设备
    [[DLCloudDeviceManager sharedInstance] autoConnectCloudDevice];
    // 为设备列表排序
    [self sortDeviceList];
    
    // 界面调整
    self.topBodyViewTopConstraint.constant += 64;
    if ([InCommon isIPhoneX]) { //iphonex
        //iphoneX底部和顶部需要多留20px空白
        self.topBodyViewTopConstraint.constant += 20;
        self.bottomBtnViewHeightConstaint.constant += 20;
        self.controlBtnBottomConstraint.constant += 20;
    }
    
    // 设置按钮圆弧
    self.controlDeviceBtn.layer.masksToBounds = YES;
    self.controlDeviceBtn.layer.cornerRadius = 5;
    
    [self setupNarBar];
    [self addDeviceListView];
    [self addSettingView];
    
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = NO;
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    // 实时监听设备的RSSI值更新
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceRSSIChange:) name:DeviceRSSIChangeNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceRSSIChangeNotification object:nil];
    UINavigationController *nav = [UIApplication sharedApplication].keyWindow.rootViewController;
    NSLog(@"self.navigationController.viewControllers = %@", nav.viewControllers);
    NSLog(@"self.navigationController.viewControllers.lastObject = %@", nav.viewControllers.lastObject);
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


- (void)addDeviceListView {
    self.deviceListVC = [InDeviceMenuViewController menuViewControllerWithCloudList:[self sortDeviceList]];
    self.deviceListVC.delegate = self;
    [self addChildViewController:self.deviceListVC];
    [self.deviceListBodyView addSubview:self.deviceListVC.view];
    self.deviceListVC.view.frame = self.deviceListBodyView.bounds;
    [self menuViewController:self.deviceListVC moveDown:MAXFLOAT];
}

- (void)addCoverView {
    if (self.coverView != nil) {
        return;
    }
    // 添加覆盖层
    UIView *view = [[UIView alloc] init];
//    [self.navigationController.view.superview addSubview:view];
    [self.view addSubview:view];
    view.frame = [UIScreen mainScreen].bounds;
    view.backgroundColor = [UIColor blackColor];
    [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideCoverView)]];
    view.alpha = 0;
    self.coverView = view;
}

- (void)removeCoverView {
    [self.coverView removeFromSuperview];
    self.coverView = nil;
}

#pragma mark - SettingView
- (void)hideCoverView {
    [self hideSettingView];
}
- (void)addSettingView {
    if (self.settingVC) {
        return;
    }
    [self addCoverView];
    // 添加用户设置界面
    InUserSettingViewController *settingVC = [[InUserSettingViewController alloc] init];
//    InUserSettingViewController *settingVC = [InUserSettingViewController UserSettingViewController];
//    [self.navigationController addChildViewController:settingVC];
//    [self.navigationController.view.superview addSubview:settingVC.view];
    [self addChildViewController:settingVC];
    [self.view addSubview:settingVC.view];
    self.settingView = settingVC.view;
//    CGFloat y = 0;
//    CGFloat width = [UIScreen mainScreen].bounds.size.width * 0.85;
//    CGFloat height = [UIScreen mainScreen].bounds.size.height-y;
//    CGFloat x = -width;
    CGFloat y = 0;
    CGFloat width = [UIScreen mainScreen].bounds.size.width * 1.45;
    CGFloat height = [UIScreen mainScreen].bounds.size.height-y;
    CGFloat x = -width;
    settingVC.view.frame = CGRectMake(x, y, width, height);
    settingVC.delegate = self;
    self.settingVC = settingVC;
    settingVC.logoutUser = ^{
        UIViewController *loginVC = self.navigationController.viewControllers[1];
        NSLog(@"退出账户");
        [self safePopViewController:loginVC];
    };
}


- (void)hideSettingView {
    self.navigationController.navigationBar.hidden = NO;
    [self settingViewController:self.settingVC touchEnd:CGPointMake(MAXFLOAT, 0)];
}


- (void)setupNarBar {
    self.navigationController.navigationBar.hidden = NO;
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"innwayLOGO"]];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"user"] style:UIBarButtonItemStylePlain target:self action:@selector(goToSettingVC)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_menu"] style:UIBarButtonItemStylePlain target:self action:@selector(goToGetPhoto)];
}

- (void)goToSettingVC {
    self.coverView.alpha = coverViewAlpha; // 显示覆盖层
    [self settingViewController:self.settingVC touchEnd:CGPointMake(-MAXFLOAT, 0)];
}

- (void)goToGetPhoto {
    NSLog(@"去获取图片");
}

- (void)safePopViewController: (UIViewController *)viewController {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController popToViewController:viewController animated:YES];
        return;
    }
    NSInteger count = self.navigationController.viewControllers.count;
    if (count >= 2) {
        if (self.navigationController.viewControllers[count - 2] == self) {
//            [self removeSettingView];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.navigationController popToViewController:viewController animated:YES];
            });
        }
    }
}
        

- (void)safePushViewController:(UIViewController *)viewController {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController pushViewController:viewController animated:YES];
        return;
    }
    NSInteger count = self.navigationController.viewControllers.count;
    if (count >= 2) {
        if (self.navigationController.viewControllers[count - 2] == self) {
//            [self removeSettingView];
            [self.navigationController pushViewController:viewController animated:NO];
        }
    }
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
    InDeviceSettingViewController *vc = [InDeviceSettingViewController deviceSettingViewController];
    vc.device = self.device;
    [self safePushViewController:vc];
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
    [self.deviceListVC reloadView:nil];
    [self updateAnnotation];
}

- (void)device:(DLDevice *)device didUpdateData:(NSDictionary *)data{
    if (device == self.device) {
        [self updateUI];
    }
}

#pragma menuViewDelegate
- (void)menuViewController:(InDeviceMenuViewController *)menuVC didSelectedDevice:(DLDevice *)device {
    [self menuViewController:self.deviceListVC moveDown:MAXFLOAT];
    if (device != self.device) {
        [self updateDevice:device];
    }
}

- (void)menuViewControllerDidSelectedToAddDevice:(InDeviceMenuViewController *)menuVC {
    InAddDeviceStartViewController *addDeviceStartVC = [InAddDeviceStartViewController addDeviceStartViewController:YES];
    [self safePushViewController:addDeviceStartVC];
}

- (void)menuViewController:(InDeviceMenuViewController *)menuVC moveDown:(CGFloat)down {
    if (down > 0) {
        //往下
        CGFloat minHeight = 196;
//        CGFloat minHeight = 146;
        if ([DLCloudDeviceManager sharedInstance].cloudDeviceList.count > 1) {
            minHeight = 146;
        }
        CGFloat maxMenuHeight = [UIScreen mainScreen].bounds.size.height * 0.5;
        if (maxMenuHeight + self.deviceListBodyHeightConstraint.constant - down < minHeight) {
            down = maxMenuHeight + self.deviceListBodyHeightConstraint.constant - minHeight;
            menuVC.down = NO;
        }
    }
    else {
        // 往上
        if (self.deviceListBodyHeightConstraint.constant - down > 0) {
            down = self.deviceListBodyHeightConstraint.constant;
            menuVC.down = YES;
        }
    }
    self.deviceListBodyHeightConstraint.constant -= down;
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
    bool hideNaviBar = NO;
    CGFloat width = settingVC.view.bounds.size.width;
    CGRect frame = settingVC.view.frame;
    CGFloat x = frame.origin.x - move.x;
    if (x >= -0.5 * width) {
        frame.origin.x = 0;
        hideNaviBar = YES;
    }
    else if (x <= -0.5 * width){
        frame.origin.x = -width;
        hideNaviBar = NO;
    }
    CGFloat alpha = (width + frame.origin.x) / width * coverViewAlpha;
    [UIView animateWithDuration:0.25 animations:^{
        settingVC.view.frame = frame;
        self.coverView.alpha = alpha;
        self.navigationController.navigationBar.hidden = hideNaviBar;
    }];
}

- (void)settingViewController:(InUserSettingViewController *)settingVC didSelectRow:(NSInteger)row {
    switch (row) {
        case 0:
        {
            NSLog(@"跳转到忘记密码");
            UIViewController *vc = [[UIViewController alloc] init];
//            [self removeSettingView];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
            
        default:
            break;
    }
}

- (void)updateDevice:(DLDevice *)device {
    self.device.delegate = nil;
    self.device = device;
    self.device.delegate = self;
    [self.deviceListVC reloadView:[self sortDeviceList]];
    [self.device getDeviceInfo];
    [self updateUI];
    [self toLocation];
}

- (void)deviceSettingBtnDidClick:(DLDevice *)device {
//    if (!device.online) {
//        return;
//    }
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


/**
 将设备列表排序：若当前有指定设备，第一台设备显示指定设备，其余设备按连接到未连接的顺序排序
 若当前没有指定设备，所有设备按连接到未连接的顺序排序
 @return
 */
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

@end
