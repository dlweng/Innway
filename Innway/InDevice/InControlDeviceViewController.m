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
#import "NSTimer+InTimer.h"
#import "InCameraViewController.h"
#import "InWebViewController.h"
#define coverViewAlpha 0.85  // 覆盖层的透明度

@interface InControlDeviceViewController ()<DLDeviceDelegate, InDeviceListViewControllerDelegate, MKMapViewDelegate, InUserSettingViewControllerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate, InCameraViewControllerDelegate>


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
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mapTopConstraint;


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

// 按钮闪烁动画
@property (nonatomic, strong) NSTimer *animationTimer;
@property (nonatomic, assign) BOOL isBtnAnimation; // 标识按钮动画是否开启
@property (nonatomic, assign) BOOL btnTextIsHide;
// 标识当前是否在拍照界面，是的话接收到设备的05命令不要发出查找手机的警报，而是要拍照
@property (nonatomic, assign) BOOL inTakePhoto;
// 标识当前正在查找手机的设备
@property (nonatomic, strong) NSMutableDictionary *searchPhoneDevices;
@property (nonatomic, strong) InCameraViewController *cameraVC;
@end

@implementation InControlDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 有iBeacon激活进入的控制界面需要结束后台任务
    [common stopiBeaconBackgroundTask];
    
    // 界面调整
    self.topBodyViewTopConstraint.constant += 64;
    if ([InCommon isIPhoneX]) { //iphonex
        //iphoneX底部和顶部需要多留20px空白
        self.topBodyViewTopConstraint.constant += 20;
        self.bottomBtnViewHeightConstaint.constant += 20;
        self.controlBtnBottomConstraint.constant += 20;
    }
    
    if ([UIScreen mainScreen].bounds.size.width >= 768) {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
            //解决iPad竖屏上方会有空白的问题
            self.mapTopConstraint.constant -= 18;
        }
    }
    
    // 设置按钮圆弧
    self.controlDeviceBtn.layer.masksToBounds = YES;
    self.controlDeviceBtn.layer.cornerRadius = 5;
    
    // 设置界面
    [self setupNarBar];
    [self addDeviceListView];
    [self addSettingView];
    
    //地图设置
    self.mapView.delegate = self;
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    
    // 实时监听设备的RSSI值更新
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceRSSIChange:) name:DeviceRSSIChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceChangeOnline:) name:DeviceOnlineChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchPhone:) name:DeviceSearchPhoneNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchDeviceAlert:) name:DeviceSearchDeviceAlertNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopBtnAnimation) name:DeviceGetAckFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUI) name:ApplicationWillEnterForeground object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeOrientation) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    // 设置定时器
    __weak typeof(self) weakSelf = self;
    self.animationTimer = [NSTimer newTimerWithTimeInterval:0.4 repeats:YES block:^(NSTimer * _Nonnull timer) {
//        NSLog(@"按钮动画");
        [weakSelf showBtnAnimation];
    }];
    [[NSRunLoop currentRunLoop] addTimer:self.animationTimer forMode:NSRunLoopCommonModes];
    [self stopBtnAnimation];
    
    // 隐私信息弹框提示
    if (![common isOpensLocation]) {
        [InAlertView showAlertWithMessage:@"Go to Location Services and allow the app to use your current location." confirmHanler:^{
            [common goToAPPSetupView];
        } cancleHanler:nil];
    }
    if (![InCommon isOpenNotification]) {
        [InAlertView showAlertWithMessage:@"Go to Settings and enable Notifications to receive Find Your Phone and Separation alerts." confirmHanler:^{
            [common goToAPPSetupView];
        } cancleHanler:nil];
    }
    self.searchPhoneDevices = [NSMutableDictionary dictionary];
    
    // 自动连接设备
    [[DLCloudDeviceManager sharedInstance] autoConnectCloudDevice];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 设置设备列表选中设备
    DLCloudDeviceManager *cloudManager = [DLCloudDeviceManager sharedInstance];
    if (cloudManager.cloudDeviceList.count > 0) {
        if (self.deviceListVC.selectDevice && [cloudManager.cloudDeviceList objectForKey:self.deviceListVC.selectDevice.mac]) {
            // 当设备列表已有选中设备，且存在云端列表中，不需要重新设置
        }
        else {
            NSString *mac = cloudManager.cloudDeviceList.allKeys[0];
            DLDevice *device = cloudManager.cloudDeviceList[mac];
            self.device = device;
            self.deviceListVC.selectDevice = self.device;
        }
    }
    
    [self.deviceListVC reloadView];
    [self.device getDeviceInfo];
    [self updateUI];
    
    // 设置是否显示用户位置
    // 在viewDidLoad设置没有效果
    self.mapView.showsUserLocation = YES;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.mapView.showsUserLocation = [common getIsShowUserLocation];
    });
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceRSSIChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceOnlineChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceSearchPhoneNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceSearchDeviceAlertNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceGetAckFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ApplicationWillEnterForeground object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
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
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        // 在后台不用去更新，因为每次界面显示都会更新一次UI
        return;
    }
    [self setupControlDeviceBtnText];
    [self.deviceListVC reloadView];
    [self updateAnnotation];
}

- (void)setupControlDeviceBtnText {
    NSString *deviceName = self.device.deviceName;
    [self.controlDeviceBtn setTitle:[NSString stringWithFormat:@"Ring %@", deviceName] forState:UIControlStateNormal];
}

- (void)addDeviceListView {
    self.deviceListVC = [InDeviceListViewController deviceListViewController];
    self.deviceListVC.delegate = self;
    self.deviceListVC.selectDevice = self.device;
    [self addChildViewController:self.deviceListVC];
    [self.deviceListBodyView addSubview:self.deviceListVC.view];
    self.deviceListVC.view.frame = self.deviceListBodyView.bounds;
    [self deviceListViewController:self.deviceListVC moveDown:YES];
}

#pragma mark - SettingView
- (void)addCoverView {
    if (self.coverView) {
        return;
    }
    // 添加覆盖层
    UIView *view = [[UIView alloc] init];
    [self.view addSubview:view];
//    view.frame = [UIScreen mainScreen].bounds;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    view.frame = CGRectMake(0, 0, height * 2, height * 2);
    view.backgroundColor = [UIColor blackColor];
    [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideSettingView)]];
    view.alpha = 0;
    self.coverView = view;
}

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
    else if (screenWidth == 768 || screenWidth == 1024 || screenWidth == 834){ //iPad
        scale = 0.4;
    }
    else if (screenWidth == 1366 || screenWidth == 1194 || screenWidth == 1112) {
        scale = 0.3;
    }
//    else if (screenWidth == 834)
    
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width * scale;
    CGFloat x = -width;
    settingVC.view.frame = CGRectMake(x, y, width, height);
    settingVC.delegate = self;
    self.settingVC = settingVC;
    self.settingView.hidden = YES;
    __weak typeof(self) weakSelf = self;
    settingVC.logoutUser = ^{
        UIViewController *loginVC = weakSelf.navigationController.viewControllers[1];
        NSLog(@"退出账户");
        [weakSelf safePopViewController:loginVC];
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
    BOOL stopSound = NO;
    if (self.searchPhoneDevices.count > 0) {
        // 1.有设备正在查找手机，去关闭查找手机的声音
        for (NSString *mac in self.searchPhoneDevices.allKeys) {
            DLDevice *device = self.searchPhoneDevices[mac];
            device.isSearchPhone = NO;
        }
        [self.searchPhoneDevices removeAllObjects];
        [self stopSearchPhone];
        stopSound = YES;
    }
    // 2.关闭离线警报
    NSDictionary *cloudDeviceList = [[DLCloudDeviceManager sharedInstance].cloudDeviceList copy];
    for (NSString *mac in cloudDeviceList) {
        DLDevice *device = cloudDeviceList[mac];
        if (device.isOfflineSounding) {
            stopSound = YES;
        }
        device.isOfflineSounding = NO;
    }
    if (stopSound) {
        return;
    }
//    NSLog(@"下发控制指令");
    if (self.device.online) {
        if (self.device.isSearchDevice) {
            self.device.isSearchDevice = NO;
            NSLog(@"关闭查找设备");
            [self stopBtnAnimation];
        }
        else {
            NSLog(@"打开查找设备");
            self.device.isSearchDevice = YES;
            [self startBtnAnimation];
            [self.device startSearchDeviceTimer]; // 开启查找需要监听，防止出现发送失败，一直在闪烁按钮的问题
        }
        [self.device searchDevice]; 
    }
    else {
        if (self.device.isSearchDevice) { // 离线状态，如果手机在查找设备，要去关闭按钮动画
            self.device.isSearchDevice = NO;
            [self stopBtnAnimation];
        }
    }
}

//进入设备设置界面
- (void)goToDeviceSettingVC:(DLDevice *)device {
    NSLog(@"进入设备设置界面");
    InDeviceSettingViewController *vc = [InDeviceSettingViewController deviceSettingViewController];
    vc.device = device;
    [self safePushViewController:vc];
}

- (IBAction)toLocation {
    NSLog(@"开始定位");
    // 1.旧的方式
    //    [self.mapView setCenterCoordinate:self.mapView.userLocation.coordinate];
    // 2.新的方式，设置显示的范围
    //设置地图中的的经度、纬度
    CLLocationCoordinate2D center = self.mapView.userLocation.coordinate;
    //设置地图显示的范围
    MKCoordinateSpan span;
    //地图显示范围越小，细节越清楚；
    span.latitudeDelta = 0.01;
    span.longitudeDelta = 0.01;
    //创建MKCoordinateRegion对象，该对象代表地图的显示中心和显示范围
    MKCoordinateRegion region = {center,span};
    //设置当前地图的显示中心和显示范围
    [self.mapView setRegion:region animated:YES];
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
    [self.device getDeviceInfo];
    [self updateUI];
//    [self toLocation];
}

- (void)deviceSettingBtnDidClick:(DLDevice *)device {
    [self goToDeviceSettingVC:device];
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
    [InCommon setNavgationBar:nav.navigationBar];
    // 设置导航栏标题颜色
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    attrs[NSForegroundColorAttributeName] = [UIColor whiteColor];
    [nav.navigationBar setTitleTextAttributes:attrs];
}

// 设备列表-上下滑动的处理
- (void)deviceListViewController:(InDeviceListViewController *)menuVC moveDown:(BOOL)down {
    CGFloat heightConstant;
    if (down) {
        //往下
        CGFloat minHeight = 196;
        CGFloat maxMenuHeight = [UIScreen mainScreen].bounds.size.height * 0.5;
        heightConstant = minHeight - maxMenuHeight;
    }
    else {
        // 往上
        heightConstant = 0;
    }
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.25 animations:^{
        weakSelf.deviceListBodyHeightConstraint.constant = heightConstant;
    }];
  
}

#pragma mark - settingVCDelegate
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
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.05 animations:^{
        settingVC.view.frame = frame;
        weakSelf.coverView.alpha = alpha;
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
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.25 animations:^{
        settingVC.view.frame = frame;
        weakSelf.coverView.alpha = alpha;
        weakSelf.settingView.hidden = !hideNaviBar;
        weakSelf.navigationController.navigationBar.hidden = hideNaviBar;
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
            NSLog(@"跳转到购买中心");
            InWebViewController *webVC = [[InWebViewController alloc] initWithTitle:@"Buy an Innway" UrlString:@"http://www.innwaytech.com"];
            [self safePushViewController:webVC];
//            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.innwaytech.com"]];
            break;
        }
        case 2:
        {
            NSLog(@"跳转到帮助中心");
            InWebViewController *webVC = [[InWebViewController alloc] initWithTitle:@"Help Center" UrlString:@"http://3.16.195.135/FAQs/help.html"];
            [self safePushViewController:webVC];
//            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://3.16.195.135/FAQs/help.html"]];
            break;
        }
        case 3:
        {
            NSLog(@"跳转到反馈中心");
            InFeedbackViewController *feedbackVC = [[InFeedbackViewController alloc] init];
            [self safePushViewController:feedbackVC];
            break;
        }
        case 4:
        {
            NSLog(@"跳转隐私协议");
            InWebViewController *webVC = [[InWebViewController alloc] initWithTitle:@"Privacy Policy" UrlString:@"http://3.16.195.135/PrivacyPolicy/PrivacyPolicy.html"];
            [self safePushViewController:webVC];
//            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.baidu.com"]];
            break;
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
//    NSLog(@"地图用户位置更新, %f, %f", userLocation.coordinate.latitude, userLocation.coordinate.longitude);
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
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        return;
    }
    NSMutableDictionary *cloudDeviceList = [DLCloudDeviceManager sharedInstance].cloudDeviceList;
    // 1.先删除已经不存在云端列表的设备大头针
    NSMutableArray *removeArr = [NSMutableArray array];
    for (NSString *mac in self.deviceAnnotation.allKeys) {
        DLDevice *device = cloudDeviceList[mac];
        if (!device) {
            // 设备不存在，假如到删除列表
            [removeArr addObject:mac];
        }
    }
    for (NSString *mac in removeArr) {
        InAnnotation *annotation = [self.deviceAnnotation objectForKey:mac];
        [self.mapView removeAnnotation:annotation];
        [self.deviceAnnotation removeObjectForKey:mac];
    }
    // 2.更新存在云端列表设备的大头针状态
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
            annotation.title = [NSString stringWithFormat:@"%@", device.deviceName];
            annotation.coordinate = device.coordinate;
            __weak typeof(self) weakSelf = self;
            [self reversGeocode:annotation.coordinate completion:^(NSString *str) {
                annotation.subtitle = str;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf.mapView selectAnnotation:annotation animated:YES];
                });
            }];
            annotation.device = device;
            [self.deviceAnnotation setObject:annotation forKey:mac];
            [self.mapView addAnnotation:annotation];
        }
        else if(!device.online && annotation) {
            annotation.title = [NSString stringWithFormat:@"%@", device.deviceName];
            annotation.coordinate = device.coordinate;
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
    //跳转系统地图
    CLLocationCoordinate2D loc = CLLocationCoordinate2DMake([lat doubleValue], [lon doubleValue]);
    MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
    MKMapItem *toLocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:loc addressDictionary:nil]];
    [MKMapItem openMapsWithItems:@[currentLocation, toLocation]
     
                   launchOptions:@{MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                                   
                                   MKLaunchOptionsShowsTrafficKey: [NSNumber numberWithBool:YES]}];
    
    return;
}

- (void)deviceRSSIChange:(NSNotification *)noti {
    DLDevice *device = noti.object;
    if (device.mac == self.device.mac) {
        [self updateUI];
    }
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
    self.cameraVC = [[InCameraViewController alloc] init];
    self.cameraVC.delegate = self;
    [self presentViewController:self.cameraVC animated:YES completion:nil];
    self.inTakePhoto = YES;
}

- (void)cameraViewControllerDidChangeToLibrary:(BOOL)isLibrary {
    NSLog(@"相机与相册界面在切换: %d",  isLibrary);
    self.inTakePhoto = !isLibrary;
}

- (void)cameraViewControllerDidClickGoBack:(InCameraViewController *)vc {
    self.inTakePhoto = NO;
    [self.cameraVC dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 按钮动画
// 查找设备的按钮动画存在一个问题：由于查找设备回复和通过设备主动控制上报的值是相同的，无法分辨，在打开设备的时候，去关闭，马上又打开，可能会出现动画被停止重新开始的情况：手机打开 -> 设备回复在被查找，并警报 -> 手机关闭按钮 -> 手机打开按钮 ->(关闭到打开的时间太短，所以这里又回了一次设备被关闭的回复，动画被关闭) -> 刚刚最后一次打开的回复（动画重新被打开）
// 没有改进方案，因为无法辨别是回复还是设备被找到，设备的按钮被按的情况，所以在每次回复都肯定要处理,否则没有处理回复，意味着按设备按钮无法关闭手机按钮的动画,下发指令到回复测试2秒左右
- (void)startBtnAnimation {
//    NSLog(@"打开按钮动画");
    if (!self.isBtnAnimation) {
        self.isBtnAnimation = YES;
        self.btnTextIsHide = NO;
        [self.animationTimer setFireDate:[NSDate distantPast]];
    }
}

- (void)stopBtnAnimation {
//    NSLog(@"关闭按钮动画");
    self.isBtnAnimation = NO;
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
    if (self.inTakePhoto) {
        [self.cameraVC takeAPhoto];
        return;
    }
    DLDevice *device = noti.userInfo[@"Device"];
    if (device.isSearchPhone) {
        device.isSearchPhone = NO;
        [self.searchPhoneDevices removeObjectForKey:device.mac];
        [self stopSearchPhone];
    }
    else {
        if (self.searchPhoneDevices.count == 0) {
            // 只有当前没有设备在查找手机的时候才去开启动画
            [self startBtnAnimation];
        }   
        device.isSearchPhone = YES;
        [self.searchPhoneDevices setValue:device forKey:device.mac];        
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
            // 发送本地通知
            [InCommon sendLocalNotification:[NSString stringWithFormat:@"%@ is finding iPhone now!", device.deviceName]];
        }
    }
}

- (void)stopSearchPhone {
    if (self.searchPhoneDevices.count == 0) {
        [self stopBtnAnimation];
    }
}

- (void)homeBtnDidClick {
    NSLog(@"home键被按");
}

- (void)searchDeviceAlert:(NSNotification *)noti {
    DLDevice *device = noti.userInfo[@"device"];
    if (device == self.device) {
        if (device.isSearchDevice) {
            [self startBtnAnimation];
        }
        else {
            [self stopBtnAnimation];
        }
    }
}

#pragma mark - 旋转屏幕
- (void)didChangeOrientation
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        //解决横屏设备列表显示不全的问题
        CGFloat maxMenuHeight = [UIScreen mainScreen].bounds.size.height * 0.5;
        CGFloat minMenuHeigth = 196;
        if (maxMenuHeight + self.deviceListBodyHeightConstraint.constant < minMenuHeigth) {
            self.deviceListBodyHeightConstraint.constant = minMenuHeigth - maxMenuHeight;
        }
    }
 
}

#pragma mark - Properity
- (NSMutableDictionary *)deviceAnnotation {
    if (!_deviceAnnotation) {
        _deviceAnnotation = [NSMutableDictionary dictionary];
    }
    return _deviceAnnotation;
}

//- (AVCaptureSession *)captureSession
//{
//    if(_captureSession == nil)
//    {
//        _captureSession = [[AVCaptureSession alloc] init];
//        //设置分辨率
//        if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
//            _captureSession.sessionPreset=AVCaptureSessionPreset1280x720;
//        }
//        
//        //添加摄像头
//        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
//        NSLog(@"devices = %@", devices);
//        for (AVCaptureDevice *device in devices) {
//            AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
//            if ([_captureSession canAddInput:deviceInput]){
//                [_captureSession addInput:deviceInput];
//            }
//        }
//    }
//    return _captureSession;
//}

@end
