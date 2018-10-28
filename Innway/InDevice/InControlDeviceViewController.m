//
//  InControlDeviceViewController.m
//  Innway
//
//  Created by danly on 2018/8/4.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InControlDeviceViewController.h"
#import "InUserSettingViewController.h"
#import "InDeviceListViewController.h"
#import "InDeviceSettingViewController.h"
#import "DLCloudDeviceManager.h"
#import "InAnnotationView.h"
#import <MapKit/MapKit.h>
#import "InCommon.h"
#import "InLoginViewController.h"
#import "InAddDeviceStartViewController.h"
#import "InChangePasswordViewController.h"
#import "InSelectionViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "InFeedbackViewController.h"
#import "InHelpCenterSelectionController.h"
#define coverViewAlpha 0.85  // 覆盖层的透明度

@interface InControlDeviceViewController ()<DLDeviceDelegate, InDeviceListViewControllerDelegate, MKMapViewDelegate, InUserSettingViewControllerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topBodyViewTopConstraint;
@property (weak, nonatomic) IBOutlet UIView *topBodyView;
@property (weak, nonatomic) IBOutlet UIButton *controlDeviceBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *controlBtnBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomBtnViewHeightConstaint;

// 设置界面
@property (nonatomic, weak) UIView *settingView;
@property (nonatomic, weak) UIViewController *settingVC;
@property (nonatomic, strong) NSLayoutConstraint *settingViewLeftConstraint;
@property (nonatomic, strong) NSLayoutConstraint *settingViewHeightConstraint;

// 设备列表
@property (weak, nonatomic) IBOutlet UIView *deviceListBodyView;
@property (weak, nonatomic) IBOutlet UIView *deviceListBackgroupView;
@property (nonatomic, strong)InDeviceListViewController *deviceListVC;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deviceListBodyHeightConstraint;

// 地图
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
// 存储掉线设备大头针的位置
@property (nonatomic, strong) NSMutableDictionary *deviceAnnotation;

// 显示设置界面的透明覆盖层
@property (nonatomic, weak) UIView *coverView;

// 拍照
@property (strong, nonatomic) IBOutlet UIView *customTakePhotoView;
@property (weak, nonatomic) IBOutlet UIView *imageBodyView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong,nonatomic)UIImagePickerController * imagePikerViewController;
@property (nonatomic, strong) UIImagePickerController *libraryPikerViewController;

// 按钮闪烁动画
@property (nonatomic, strong) NSTimer *animationTimer;
@property (nonatomic, assign) BOOL btnTextIsHide;
@property (nonatomic, assign) BOOL isSearchPhone;
@property (nonatomic, assign) BOOL isSearchDevice;
@end

@implementation InControlDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
    [self setUpImagePiker];
    [[DLCloudDeviceManager sharedInstance] autoConnectCloudDevice];
    
    //地图设置
    self.mapView.delegate = self;
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    
    // 实时监听设备的RSSI值更新
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceRSSIChange:) name:DeviceRSSIChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceChangeOnline:) name:DeviceOnlineChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchPhone:) name:DeviceSearchPhoneNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchDeviceAlert:) name:DeviceSearchDeviceAlertNotification object:nil];
    
    // 添加云端列表的监视
    [[DLCloudDeviceManager sharedInstance] addObserver:self forKeyPath:@"cloudDeviceList" options:NSKeyValueObservingOptionNew context:nil];
    
    // 设置定时器
    self.animationTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(showBtnAnimation) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.animationTimer forMode:NSRunLoopCommonModes];
    [self stopBtnAnimation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 为设备列表排序
    [self sortDeviceList];
    [self.device getDeviceInfo];
    [self updateAnnotation];
    [self updateUI];
    // 在viewDidLoad设置没有效果
    self.mapView.showsUserLocation = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.mapView.showsUserLocation = [common getIsShowUserLocation];
    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceRSSIChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceOnlineChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceSearchPhoneNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceSearchDeviceAlertNotification object:nil];
    [[DLCloudDeviceManager sharedInstance] removeObserver:self forKeyPath:@"cloudDeviceList"];
    [self.animationTimer invalidate];
    self.animationTimer = nil;
}

#pragma mark UI设置
- (void)setupNarBar {
    self.navigationController.navigationBar.hidden = NO;
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"innwayLOGO"]];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"user"] style:UIBarButtonItemStylePlain target:self action:@selector(goToSettingVC)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_menu"] style:UIBarButtonItemStylePlain target:self action:@selector(goToGetPhoto)];
}

- (void)updateUI {
    [self setupControlDeviceBtnText];
    [self.deviceListVC reloadView:nil];
    [self updateAnnotation];
}

- (void)setupControlDeviceBtnText {
    NSString *deviceName = self.device.deviceName;
    [self.controlDeviceBtn setTitle:[NSString stringWithFormat:@"Ring Innway %@", deviceName] forState:UIControlStateNormal];
}

- (void)addDeviceListView {
    self.deviceListVC = [InDeviceListViewController deviceListViewController];
    self.deviceListVC.delegate = self;
    [self addChildViewController:self.deviceListVC];
    [self.deviceListBodyView addSubview:self.deviceListVC.view];
    self.deviceListVC.view.frame = self.deviceListBodyView.bounds;
    [self deviceListViewController:self.deviceListVC moveDown:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"keyPath = %@发生改变, change = %@, object = %@",keyPath, change, object);
}

#pragma mark - SettingView
- (void)addCoverView {
    if (self.coverView) {
        return;
    }
    // 添加覆盖层
    UIView *view = [[UIView alloc] init];
    [self.view addSubview:view];
    view.frame = [UIScreen mainScreen].bounds;
    view.backgroundColor = [UIColor blackColor];
    [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideSettingView)]];
    view.alpha = 0;
    self.coverView = view;
}

//- (void)addSettingView {
//    if (self.settingVC) {
//        return;
//    }
//    [self addCoverView];
//    // 添加用户设置界面
//    InUserSettingViewController *settingVC = [[InUserSettingViewController alloc] init];
//    [self addChildViewController:settingVC];
//    [self.view addSubview:settingVC.view];
//    self.settingView = settingVC.view;
//    UIView *settingView = settingVC.view;
//    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
//    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.settingView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
//    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.settingView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
//    self.settingViewLeftConstraint = [NSLayoutConstraint constraintWithItem:self.settingView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
//    [self.view addConstraint:self.settingViewLeftConstraint];
//    self.settingViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.settingView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:screenWidth * 0.85];
//    [self.view addConstraint:self.settingViewHeightConstraint];
//
//    settingVC.delegate = self;
//    self.settingVC = settingVC;
//    self.settingView.hidden = YES;
//    settingVC.logoutUser = ^{
//        UIViewController *loginVC = self.navigationController.viewControllers[1];
//        NSLog(@"退出账户");
//        [self safePopViewController:loginVC];
//    };
//}

- (void)addSettingView {
    if (self.settingVC) {
        return;
    }
    [self addCoverView];
    // 添加用户设置界面
    InUserSettingViewController *settingVC = [[InUserSettingViewController alloc] init];
    [self addChildViewController:settingVC];
    [self.view addSubview:settingVC.view];
    self.settingView = settingVC.view;

    // IPHONEX = 1.45
    // XR = 1.35
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat scale = 0.85;
    CGFloat y = 0;
    CGFloat height = [UIScreen mainScreen].bounds.size.height-y;
//    NSLog(@"screenWidth = %f, screenHeight = %f", screenWidth, [UIScreen mainScreen].bounds.size.height);
    if (screenWidth == 375) {
        //iPhoneX = iPhoneXS = 375 * 812
        scale = 1.4;
    }
    else if (screenWidth == 414) {
        // iPhone XR, iPhoneXS Max 414 * 896
        // iPhone 8P, 414 * 736
        scale = 1.25;
    }
    else if (screenWidth == 320) {
        // iphone 5s
        scale = 1.7;
        height += 50;
    }
    CGFloat width = [UIScreen mainScreen].bounds.size.width * scale;
    CGFloat x = -width;
    settingVC.view.frame = CGRectMake(x, y, width, height);
    settingVC.delegate = self;
    self.settingVC = settingVC;
    self.settingView.hidden = YES;
    settingVC.logoutUser = ^{
        UIViewController *loginVC = self.navigationController.viewControllers[1];
        NSLog(@"退出账户");
        [self safePopViewController:loginVC];
    };
}

- (void)goToSettingVC {
    self.settingView.hidden = NO;
    [self settingViewController:(InUserSettingViewController *)self.settingVC touchEnd:CGPointMake(-MAXFLOAT, 0)];
}

- (void)hideSettingView {
    self.navigationController.navigationBar.hidden = NO;
    [self settingViewController:(InUserSettingViewController *)self.settingVC touchEnd:CGPointMake(MAXFLOAT, 0)];
}

#pragma mark - Action
//控制设备
- (IBAction)controlDeviceBtnDidClick:(UIButton *)sender {
    if (self.isSearchPhone) {
        [self stopSearchPhone];
        return;
    }
    NSLog(@"下发控制指令");

//    if (self.isSearchDevice) {
//        self.isSearchDevice = NO;
//        [self stopBtnAnimation];
//    }
//    else {
//        self.isSearchDevice = YES;
//        [self startBtnAnimation];
//    }
    [self.device searchDevice];
}

//进入设备设置界面
- (void)goToDeviceSettingVC {
    NSLog(@"进入设备设置界面");
    InDeviceSettingViewController *vc = [InDeviceSettingViewController deviceSettingViewController];
    vc.device = self.device;
    [self safePushViewController:vc];
}

- (IBAction)toLocation {
    NSLog(@"开始定位");
    [self.mapView setCenterCoordinate:self.mapView.userLocation.coordinate];
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

#pragma mark - 更新设备数据
- (void)device:(DLDevice *)device didUpdateData:(NSDictionary *)data{
    if (device == self.device) {
        [self updateUI];
    }
}

- (void)updateDevice:(DLDevice *)device {
    self.device = device;
    [self sortDeviceList];
    [self.device getDeviceInfo];
    [self updateUI];
    [self toLocation];
}

- (void)deviceSettingBtnDidClick:(DLDevice *)device {
    //    if (!device.online) {
    //        return;
    //    }
    [self deviceListViewController:nil didSelectedDevice:device];
    [self goToDeviceSettingVC];
}

#pragma mark - deviceListDelegate
- (void)deviceListViewController:(InDeviceListViewController *)menuVC didSelectedDevice:(DLDevice *)device {
//    [self deviceListViewController:self.deviceListVC moveDown:MAXFLOAT];
    if (device != self.device) {
        [self updateDevice:device];
    }
}

- (void)deviceListViewControllerDidSelectedToAddDevice:(InDeviceListViewController *)menuVC {
    InSelectionViewController *selectionViewController = [InSelectionViewController selectionViewController:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:selectionViewController];
    [self presentViewController:nav animated:YES completion:nil];
    [InCommon setNavgationBar:nav.navigationBar backgroundImage:[UIImage imageNamed:@"narBarBackgroudImage"]];
    // 设置导航栏标题颜色
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    attrs[NSForegroundColorAttributeName] = [UIColor whiteColor];
    [nav.navigationBar setTitleTextAttributes:attrs];
//    NSArray *subViewController = self.navigationController.viewControllers;
//    if (subViewController.count > 3) {
//        InAddDeviceStartViewController *addDeviceStartVC = subViewController[2];
//        addDeviceStartVC.canBack = YES;
//        if ([addDeviceStartVC isKindOfClass:[InAddDeviceStartViewController class]]) {
//            [self safePopViewController:addDeviceStartVC];
//        }
//    }
}

// 设备列表-上下滑动的处理
- (void)deviceListViewController:(InDeviceListViewController *)menuVC moveDown:(BOOL)down {
    CGFloat heightConstant;
    if (down) {
        //往下
        CGFloat minHeight = 196;
        //        if ([DLCloudDeviceManager sharedInstance].cloudDeviceList.count > 1) {
        //            minHeight = 146;
        //        }
        CGFloat maxMenuHeight = [UIScreen mainScreen].bounds.size.height * 0.5;
        heightConstant = minHeight - maxMenuHeight;
    }
    else {
        // 往上
        heightConstant = 0;
    }
    [UIView animateWithDuration:0.25 animations:^{
        self.deviceListBodyHeightConstraint.constant = heightConstant;
    }];
  
}
//- (void)deviceListViewController:(InDeviceListViewController *)menuVC moveDown:(CGFloat)down {
//    if (down > 0) {
//        //往下
//        CGFloat minHeight = 196;
////        if ([DLCloudDeviceManager sharedInstance].cloudDeviceList.count > 1) {
////            minHeight = 146;
////        }
//        CGFloat maxMenuHeight = [UIScreen mainScreen].bounds.size.height * 0.5;
//        if (maxMenuHeight + self.deviceListBodyHeightConstraint.constant - down < minHeight) {
//            down = maxMenuHeight + self.deviceListBodyHeightConstraint.constant - minHeight;
//            menuVC.down = NO;
//        }
//    }
//    else {
//        // 往上
//        if (self.deviceListBodyHeightConstraint.constant - down > 0) {
//            down = self.deviceListBodyHeightConstraint.constant;
//            menuVC.down = YES;
//        }
//    }
//    self.deviceListBodyHeightConstraint.constant -= down;
//}

#pragma mark - settingVCDelegate
//- (void)settingViewController:(InUserSettingViewController *)settingVC touchMove:(CGPoint)move {
//    CGFloat width = self.settingViewHeightConstraint.constant;
//    CGFloat cureentLeft = self.settingViewLeftConstraint.constant;
//    CGFloat x = cureentLeft - move.x;
//    if (x >= 0) {
//        x = 0;
//    }
//    else if (x <= -width){
//        x = -width;
//    }
//    else {
//        x = x;
//    }
//    CGFloat alpha = (width + x) / width * coverViewAlpha;
//    [UIView animateWithDuration:0.05 animations:^{
//        self.settingViewLeftConstraint.constant = x;
//        self.coverView.alpha = alpha;
//    }];
//}
//
//- (void)settingViewController:(InUserSettingViewController *)settingVC touchEnd:(CGPoint)move {
//    bool hideNaviBar = NO;
//    CGFloat width = self.settingViewHeightConstraint.constant;
//    CGFloat cureentLeft = self.settingViewLeftConstraint.constant;
//    CGFloat x = cureentLeft - move.x;
//    if (x >= -0.5 * width) {
//        x = 0;
//        hideNaviBar = YES;
//    }
//    else if (x <= -0.5 * width){
//        x = -width;
//        hideNaviBar = NO;
//    }
//    CGFloat alpha = (width + x) / width * coverViewAlpha;
//    [UIView animateWithDuration:0.25 animations:^{
//        self.settingViewLeftConstraint.constant = x;
//        self.coverView.alpha = alpha;
//        self.settingView.hidden = !hideNaviBar;
//        self.navigationController.navigationBar.hidden = hideNaviBar;
//    }];
//}

// 用户设置界面-左右滑动的处理
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
        self.settingView.hidden = !hideNaviBar;
        self.navigationController.navigationBar.hidden = hideNaviBar;
    }];
}

- (void)settingViewController:(InUserSettingViewController *)settingVC didSelectRow:(NSInteger)row {
    switch (row) {
        case 0:
        {
            NSLog(@"跳转到忘记密码");
            InChangePasswordViewController *changePwdVC = [[InChangePasswordViewController alloc] init];
            [self safePushViewController:changePwdVC];
            break;
        }
        case 1:
        {
            NSLog(@"跳转到反馈中心");
            InFeedbackViewController *feedbackVC = [[InFeedbackViewController alloc] init];
            [self safePushViewController:feedbackVC];
            break;
        }
        case 2:
        {
            NSLog(@"跳转到购买中心");
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.baidu.com"]];
            break;
        }
        case 3:
        {
            NSLog(@"跳转到帮助中心");
            InHelpCenterSelectionController *helpCenterSelectionVC = [[InHelpCenterSelectionController alloc] init];
            [self safePushViewController:helpCenterSelectionVC];
        }
        default:
            break;
    }
}

- (void)settingViewController:(InUserSettingViewController *)settingVC showUserLocation:(BOOL)showUserLocation {
    [common saveUserLocationIsShow:showUserLocation];
    self.mapView.showsUserLocation = [common getIsShowUserLocation];
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
    NSLog(@"%@", NSStringFromClass([annotation class]));
    if ([annotation isKindOfClass:[InAnnotation class]]) {
        InAnnotation *myAnnotation = (InAnnotation *)annotation;
        NSString *reuseID = @"InAnnotationView";
        InAnnotationView *annotationView = (InAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseID];
        if (annotationView == nil) {
            annotationView = [[InAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseID];
            annotationView.canShowCallout = YES;
            NSString *deviceImageName = @"Card";
            if (myAnnotation.device) {
                switch (myAnnotation.device.type) {
                    case InDeviceChip:
                        deviceImageName = @"chip";
                        break;
                    case InDeviceTag:
                        deviceImageName = @"tag";
                    default:
                        break;
                }
            }
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 38, 38)];
            [imageView setImage:[UIImage imageNamed:deviceImageName]];
            annotationView.leftCalloutAccessoryView = imageView;
            UIButton *locationBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 38, 38)];
            [locationBtn setImage:[UIImage imageNamed:@"icon_location"] forState:UIControlStateNormal];
            [locationBtn addTarget:self action:@selector(goToLocationOfflineDevice:) forControlEvents:UIControlEventTouchUpInside];
            annotationView.rightCalloutAccessoryView = locationBtn;
        }
        myAnnotation.annotationView = annotationView;
        return annotationView;
    }
    return nil;
}

- (void)goToLocationOfflineDevice:(UIButton *)btn {
    for (NSString *mac in self.deviceAnnotation.allKeys) {
        InAnnotation *annotation = self.deviceAnnotation[mac];
        if (annotation.annotationView.rightCalloutAccessoryView == btn) {
            [self goThereWithAddress:@"DJDS" andLat:[NSString stringWithFormat:@"%f", annotation.coordinate.latitude] andLon:[NSString stringWithFormat:@"%f", annotation.coordinate.longitude]];
            NSLog(@"去定位离线设备的位置, %f, %f", annotation.coordinate.longitude, annotation.coordinate.latitude);
        }
    }
}

- (void)deviceChangeOnline:(NSNotification *)notification {
//    NSLog(@"接收到设备:%@, 状态改变的通知: %@",  notification.object);
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
            annotation = [[InAnnotation alloc] init];
            annotation.title = @"innway card";
            switch (device.type) {
                case InDeviceChip:
                    annotation.title = @"innway chip";
                    break;
                case InDeviceTag:
                    annotation.title = @"innway tag";
                    break;
                default:
                    break;
            }
            annotation.coordinate = device.coordinate;
            [self reversGeocode:annotation.coordinate completion:^(NSString *str) {
                annotation.subtitle = str;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.mapView selectAnnotation:annotation animated:YES];
                });
            }];
            annotation.device = device;
            [self.deviceAnnotation setObject:annotation forKey:mac];
            [self.mapView addAnnotation:annotation];
        }
    }
}

/**
 *  反地理编码: 把经纬度转换地名
 */
- (void)reversGeocode:(CLLocationCoordinate2D)coordinate completion:(void (^)(NSString *))completion{
    //  1. 取出经纬度信息
    NSString *latitudeStr = [NSString stringWithFormat:@"%f", coordinate.latitude];
    NSString *longitudeStr = [NSString stringWithFormat:@"%f", coordinate.longitude];
    
    //  创建位置对象
    CLLocation *location = [[CLLocation alloc] initWithLatitude:latitudeStr.doubleValue longitude:longitudeStr.doubleValue];
    
    //  1. 创建地理编码器
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    //  2. 反地理编码,
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        for (CLPlacemark *placemark in placemarks) {
            NSMutableString *address = [NSMutableString stringWithString:@"Near "];
            if (placemark.subThoroughfare.length > 0) {
                [address appendFormat:@"%@ ", placemark.subThoroughfare];
            }
            if (placemark.thoroughfare.length > 0) {
                [address appendFormat:@"%@, ", placemark.thoroughfare];
            }
            if (placemark.subLocality.length > 0) {
                [address appendFormat:@"%@ ", placemark.subLocality];
            }
            if (placemark.locality.length > 0) {
                [address appendFormat:@"%@", placemark.locality];
            }
            if (completion) {
                completion(address);
            }
        }
    }];
}

-(BOOL)canOpenUrl:(NSString *)string {
    
    return  [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:string]];
    
}

- (void)goThereWithAddress:(NSString *)address andLat:(NSString *)lat andLon:(NSString *)lon {
    
    if ([self canOpenUrl:@"baidumap://"]) {///跳转百度地图
        
        NSString *urlString = [[NSString stringWithFormat:@"baidumap://map/direction?origin={{我的位置}}&destination=latlng:%@,%@|name=%@&mode=driving&coord_type=bd09ll",lat, lon,address] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        
        return;
        
    }else if ([self canOpenUrl:@"iosamap://"]) {///跳转高德地图
        
        NSString *urlString = [[NSString stringWithFormat:@"iosamap://navi?sourceApplication=%@&backScheme=%@&lat=%@&lon=%@&dev=0&style=2",@"神骑出行",@"TrunkHelper",lat, lon] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        
        return;
        
    }else{////跳转系统地图
        
        CLLocationCoordinate2D loc = CLLocationCoordinate2DMake([lat doubleValue], [lon doubleValue]);
        
        MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
        
        MKMapItem *toLocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:loc addressDictionary:nil]];
        
        [MKMapItem openMapsWithItems:@[currentLocation, toLocation]
         
                       launchOptions:@{MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                                       
                                       MKLaunchOptionsShowsTrafficKey: [NSNumber numberWithBool:YES]}];
        
        return;
        
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
 */
- (void)sortDeviceList {
    NSDictionary *cloudList = [DLCloudDeviceManager sharedInstance].cloudDeviceList;
    if (cloudList.count == 0) {
        [self.deviceListVC reloadView:@[]];
    }
    if (self.device) {
        if (![cloudList objectForKey:self.device.mac]) {
            // 如果云端不存在该设备，将当前设备设置为空
            // 当删除设备，重回控制界面的情况
            self.device = nil;
        }
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
    NSLog(@"cloudList = %@, connectList = %@", cloudList, connectList);
    [self.deviceListVC reloadView:[connectList copy]];
}

#pragma mark - 安全跳转界面
- (void)safePopViewController: (UIViewController *)viewController {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self hideSettingView];
        [self.navigationController popToViewController:viewController animated:YES];
        return;
    }
}

- (void)safePushViewController:(UIViewController *)viewController {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self hideSettingView];
        [self.navigationController pushViewController:viewController animated:YES];
        return;
    }
}

#pragma mark - Take photo
- (void)goToGetPhoto {
//    NSLog(@"去获取图片");
    self.imagePikerViewController.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePikerViewController.showsCameraControls = NO;
    [[NSBundle mainBundle] loadNibNamed:@"InCustomTablePhotoVuew" owner:self options:nil];
    self.customTakePhotoView.frame = self.imagePikerViewController.cameraOverlayView.frame;
    self.customTakePhotoView.backgroundColor = [UIColor clearColor];
    self.imagePikerViewController.cameraOverlayView = self.customTakePhotoView;
    self.customTakePhotoView = nil;
    [self presentViewController:self.imagePikerViewController animated:YES completion:NULL];
    self.imageBodyView.hidden = YES;
}

- (void)setUpImagePiker {
    // 设置相机的
    self.imagePikerViewController = [[UIImagePickerController alloc] init];
    self.imagePikerViewController.delegate = self;
    self.imagePikerViewController.allowsEditing = YES;
    // 设置相册的
    self.libraryPikerViewController = [[UIImagePickerController alloc] init];
    self.libraryPikerViewController.delegate = self;
    self.libraryPikerViewController.allowsEditing = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    // 设置相册的导航栏
    [self.libraryPikerViewController.navigationBar setBarTintColor:[UIColor clearColor]];
    [self.libraryPikerViewController.navigationBar setTranslucent:NO];
    [self.libraryPikerViewController.navigationBar setTintColor:[UIColor whiteColor]];
    [InCommon setNavgationBar:self.libraryPikerViewController.navigationBar backgroundImage:[UIImage imageNamed:@"narBarBackgroudImage"]];
    // 设置标题颜色
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    attrs[NSForegroundColorAttributeName] = [UIColor whiteColor];
    [self.libraryPikerViewController.navigationBar setTitleTextAttributes:attrs];
}
- (IBAction)setPhotoSharkLight {
    NSLog(@"设置闪光灯");
    [common setupSharkLight];
}

- (IBAction)goPhotoLibrary {
    NSLog(@"进入相册");
    // 解决iPhone5S上导航栏会消失的Bug
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.libraryPikerViewController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    [self.imagePikerViewController presentViewController:self.libraryPikerViewController animated:YES completion:NULL];
    
}

- (IBAction)takePhoto {
    NSLog(@"拍照保存");
    [self.imagePikerViewController takePicture];
}

- (IBAction)takePhotoBack {
    NSLog(@"拍完照返回");
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)goBackTakePhotoView {
    [self.imagePikerViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    if (picker == self.libraryPikerViewController) {
//        self.imageBodyView.hidden = NO;
        // 相册界面点击图片显示
//        UIImage * image = info[UIImagePickerControllerOriginalImage];
//        self.imageView.image = image;
        [self.imagePikerViewController dismissViewControllerAnimated:YES completion:NULL];
        return;
    }
    else if (picker == self.imagePikerViewController) {
        // 相机拍完照进入保存
        UIImage * image = info[UIImagePickerControllerEditedImage];
        if (!image) {
            image = info[UIImagePickerControllerOriginalImage];
        }
//        self.imageView.image = image;
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSaveImageWithError:contextInfo:), (__bridge void *)self);
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self goBackTakePhotoView];
}

- (void)image:(UIImage *)image didFinishSaveImageWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSLog(@"保存图片结果: image = %@, error = %@, contextInfo = %@", image, error, contextInfo);
}

#pragma mark - 按钮动画
- (void)startBtnAnimation {
    self.btnTextIsHide = YES; // 保持步调一致
    [self.animationTimer setFireDate:[NSDate distantPast]];
}

- (void)stopBtnAnimation {
    [self.animationTimer setFireDate:[NSDate distantFuture]];
    // 显示按钮文字
    self.btnTextIsHide = YES;
    [self showBtnAnimation];
}

- (void)showBtnAnimation {
    self.btnTextIsHide = !self.btnTextIsHide;
    if (!self.btnTextIsHide) {
        [self setupControlDeviceBtnText];
    }
    else {
        [self.controlDeviceBtn setTitle:@"" forState:UIControlStateNormal];
    }
}

- (void)searchPhone:(NSNotification *)noti {
    if (self.isSearchPhone) {
        [self stopSearchPhone];
        return;
    }
    self.isSearchPhone = YES;
    [common playSound];
    [self startBtnAnimation];
    
    // 发送本地通知
    DLDevice *device = noti.userInfo[@"Device"];
    [common sendLocalNotification:[NSString stringWithFormat:@"Innway %@ is finding iPhone now!", device.deviceName]];
}

- (void)stopSearchPhone {
    self.isSearchPhone = NO;
    [common stopSound];
    [self stopBtnAnimation];
}

- (void)searchDeviceAlert:(NSNotification *)noti {
    BOOL alertStatus = [noti.userInfo boolValueForKey:AlertStatusKey defaultValue:NO];
    if (alertStatus) {
        self.isSearchDevice = YES;
        [self startBtnAnimation];
    }
    else {
        self.isSearchDevice = NO;
        [self stopBtnAnimation];
    }
}

#pragma mark - Properity
- (NSMutableDictionary *)deviceAnnotation {
    if (!_deviceAnnotation) {
        _deviceAnnotation = [NSMutableDictionary dictionary];
    }
    return _deviceAnnotation;
}

@end
