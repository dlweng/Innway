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

@interface InControlDeviceViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewbottomGapConstraint;
@property (weak, nonatomic) IBOutlet UIButton *controlDeviceBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topBodyViewTopConstraint;
@property (weak, nonatomic) IBOutlet UIView *topBodyView;
@property (nonatomic, weak) UIView *settingView;

@property (nonatomic, strong) UIBarButtonItem *settingImageBarButton;
@property (nonatomic, strong) UIBarButtonItem *SettingTitleBarButton;

@property (weak, nonatomic) IBOutlet UIView *deviceMenuView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deviceMenuViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deviceMenuViewTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deviceMenuTopContaint;
@property (nonatomic, assign) BOOL deviceMenuIsShow;

@end

@implementation InControlDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.topBodyViewTopConstraint.constant += 64;
    if ([UIScreen mainScreen].bounds.size.height == 812) { //iphonex
        //iphoneX底部和顶部需要多留20px空白
        self.bottomViewHeightConstraint.constant += 20;
        self.bottomViewbottomGapConstraint.constant += 20;
        self.topBodyViewTopConstraint.constant += 20;
    }
    self.deviceMenuTopContaint.constant = self.topBodyViewTopConstraint.constant;
    
    // 隐藏设备菜单界面
    self.deviceMenuIsShow = YES;
    [self goToMenu];
    
    // 设置按钮圆弧
    self.controlDeviceBtn.layer.masksToBounds = YES;
    self.controlDeviceBtn.layer.cornerRadius = 5;
    
    [self setupNarBar];
    [self addSettingView];
    [self addDeviceMenu];
    self.topBodyView.backgroundColor = [UIColor redColor];
}

- (void)addDeviceMenu {
#warning 模拟设备列表
    NSArray *deviceList = @[@"dada", @"dasda"];
    InDeviceMenuViewController *deviceMenuVC = [InDeviceMenuViewController menuViewControllerWithDeviceList:deviceList];
    [self addChildViewController:deviceMenuVC];
    [self.deviceMenuView addSubview:deviceMenuVC.view];
    
    self.deviceMenuViewHeightConstraint.constant = deviceList.count * 70 + 50;
    deviceMenuVC.view.frame = CGRectMake(0, 0, self.deviceMenuView.frame.size.width, self.deviceMenuView.frame.size.height);
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
        if (self.navigationController.viewControllers.lastObject == self) {
            NSLog(@"退出账户");
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    };
    NSLog(@"settingView.frame = %@", [NSValue valueWithCGRect:self.settingView.frame]);
    NSLog(@"self.view.frame = %@", [NSValue valueWithCGRect:self.view.frame]);
    NSLog(@"bounds = %@", [NSValue valueWithCGRect:[UIScreen mainScreen].bounds]);
}

- (void)showSettingVC: (BOOL)isShow {
    CGRect frame = self.settingView.frame;
    CGPoint origin = frame.origin;
    if (isShow) {
        //显示
        origin.x = 0;
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
    }];
}

- (void)setupNarBar {
    self.navigationItem.title = @"Innway";
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
    self.deviceMenuIsShow = !self.deviceMenuIsShow;
    if (self.deviceMenuIsShow) {
        self.deviceMenuViewTrailingConstraint.constant = 0;
    }
    else {
        self.deviceMenuViewTrailingConstraint.constant = [UIScreen mainScreen].bounds.size.width * -0.7;
    }
}

#pragma mark - Action
//控制设备
- (IBAction)controlDeviceBtnDidClick:(UIButton *)sender {
    NSLog(@"下发控制指令");
}

//进入更多界面
- (IBAction)more {
    NSLog(@"进入更多界面");
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController pushViewController:[InDeviceSettingViewController deviceSettingViewController] animated:YES];
    }
}

- (IBAction)toSwitchMapMode {
    NSLog(@"切换地图模式");
}

- (IBAction)toLocation {
    NSLog(@"开始定位");
}


@end
