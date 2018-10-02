//
//  InSearchDeviceViewController.m
//  Innway
//
//  Created by danly on 2018/10/1.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InSearchDeviceViewController.h"
#import "InControlDeviceViewController.h"
#import "DLCloudDeviceManager.h"
#import "DLCentralManager.h"
#import "InCommon.h"


/**
 界面显示类型
 */
typedef NS_ENUM(NSInteger, InSearchViewType) {
    InSearch = 0,
    InSuccess = 1,
    InFailed = 2
};

@interface InSearchDeviceViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *waiting1;
@property (weak, nonatomic) IBOutlet UIImageView *waiting2;
@property (weak, nonatomic) IBOutlet UIImageView *waiting3;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *confirmBtnTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topOptionViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *searchBodyView;
@property (weak, nonatomic) IBOutlet UIView *successBodyView;
@property (weak, nonatomic) IBOutlet UIView *failedBodyView;
@property (weak, nonatomic) IBOutlet UILabel *titleTipLabel;
@property (weak, nonatomic) IBOutlet UILabel *firstTipLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondTipLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdTipLabel;
@property (weak, nonatomic) IBOutlet UIButton *confirmBtn;
@property (nonatomic, assign) InSearchViewType type;
@property (weak, nonatomic) IBOutlet UILabel *tryAagainLabel;
@property (weak, nonatomic) IBOutlet UIView *phoneBodyView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *phoneOptionViewHeightConstraint;

@property (nonatomic, strong) NSTimer *searchAnimationTimer;
@property (nonatomic, copy) NSString *findDeviceMac;

/**
 动画的显示标识
 0：隐藏所有搜索图标
 1：显示第一个搜索图标
 2：显示第二个搜索图标
 3：显示第三个搜索图标
 */
@property (nonatomic, assign) NSInteger showWating;

@end

@implementation InSearchDeviceViewController

+ (instancetype)searchDeviceViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"InAddDevice" bundle:nil];
    InSearchDeviceViewController *searchVC = [sb instantiateViewControllerWithIdentifier:@"InSearchDeviceViewController"];
    return searchVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Add a new Innway";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.searchAnimationTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(animation) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.searchAnimationTimer forMode:NSRunLoopCommonModes];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    self.topOptionViewHeightConstraint.constant = screenHeight / 3.8;
    if (screenHeight == 568) {
        // iphone 5, 4s
        self.topOptionViewHeightConstraint.constant = screenHeight / 4.3;
    }
    self.type = InSearch;
    [self updateView];
    [self stopAnimation];
    [self hideAllWating];
    self.findDeviceMac = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopAnimation];
}

- (void)updateView {
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    if (self.type == InSearch) {
        self.searchBodyView.hidden = NO;
        self.successBodyView.hidden = YES;
        self.failedBodyView.hidden = YES;
        self.tryAagainLabel.hidden = YES;
        self.phoneBodyView.hidden = NO;
        self.phoneOptionViewHeightConstraint.constant = 151;
        self.confirmBtnTopConstraint.constant = screenHeight / 14.0;
        if (screenHeight == 568) {
            self.confirmBtnTopConstraint.constant = screenHeight / 26.0;
        }
        [self.confirmBtn setTitle:@"Confirm" forState:UIControlStateNormal];
        self.titleTipLabel.text = @"Successive instructions";
        self.firstTipLabel.text = @"1. Make sure to turn on your phone's Bluetooth.";
        self.secondTipLabel.text = @"2. Hold the button on the innway card 3 sec until your hear a beep and the led starts flashing.";
        self.thirdTipLabel.text = @"3. Hold the innway card close to your phone.";
    }
    else if (self.type == InSuccess) {
        self.searchBodyView.hidden = YES;
        self.successBodyView.hidden = NO;
        self.failedBodyView.hidden = YES;
        self.tryAagainLabel.hidden = YES;
        self.phoneBodyView.hidden = NO;
        [self.confirmBtn setTitle:@"Confirm" forState:UIControlStateNormal];
        self.phoneOptionViewHeightConstraint.constant = 151;
        self.confirmBtnTopConstraint.constant = screenHeight / 14.0;
        if (screenHeight == 568) {
            self.confirmBtnTopConstraint.constant = screenHeight / 26.0;
        }
        self.titleTipLabel.text = @"Successive instructions";
        self.firstTipLabel.text = @"1. Make sure to turn on your phone's Bluetooth.";
        self.secondTipLabel.text = @"2. Hold the button on the innway card until your hear a beep and the led starts flashing.";
        self.thirdTipLabel.text = @"3. Hold the innway card close to your phone.";
    }
    else if (self.type == InFailed) {
        self.searchBodyView.hidden = YES;
        self.successBodyView.hidden = YES;
        self.failedBodyView.hidden = NO;
        self.tryAagainLabel.hidden = NO;
        self.phoneBodyView.hidden = YES;
        [self.confirmBtn setTitle:@"return" forState:UIControlStateNormal];
        self.phoneOptionViewHeightConstraint.constant = 70;
        self.confirmBtnTopConstraint.constant = 0;
        self.titleTipLabel.text = @"you can";
        self.firstTipLabel.text = @"1. Turn off and then turn on Bluetooth.";
        self.secondTipLabel.text = @"2. Hold the button on the innway card and check if can hear a beep sound.";
        self.thirdTipLabel.text = @"3. Near the innway card to your phone";
    }
}

- (IBAction)confirm {
    switch (self.type) {
        case InSearch:
        {
            NSLog(@"开始搜索新设备");
            [self startAnimation];
            [self searchNewDevice];
            break;
        }
        case InSuccess:
        {
            NSLog(@"跳转到控制界面");
            [self addNewDevice];
            break;
        }
        case InFailed: {
            NSLog(@"返回搜索");
            self.type = InSearch;
            [self updateView];
            break;
        }
        default:
            break;
    }
}

- (void)searchNewDevice {
    __block BOOL find = NO;
    [[DLCentralManager sharedInstance] startScanDeviceWithTimeout:10 discoverEvent:^(DLCentralManager *manager, CBPeripheral *peripheral, NSString *mac) {
        if (!find) {
            DLDevice *device = [[DLCloudDeviceManager sharedInstance].cloudDeviceList objectForKey:mac];
            if (!device) {
                // 找到新设备
                find = YES;
                self.type = InSuccess;
                [self stopAnimation];
                [self updateView];
                self.findDeviceMac = mac;
            }
        }
    } didEndDiscoverDeviceEvent:^(DLCentralManager *manager, NSMutableDictionary<NSString *,DLKnowDevice *> *knownPeripherals) {
        if (!find) {
            [self stopAnimation];
            [self hideAllWating];
            self.type = InFailed;
            [self updateView];
        }
    }];
}

- (void)addNewDevice {
    [[DLCloudDeviceManager sharedInstance] addDevice:self.findDeviceMac completion:^(DLCloudDeviceManager *manager, DLDevice *device, NSError *error) {
        if (error) {
            [InAlertTool showAlert:@"Tip" message:@"添加设备失败" confirmHanler:^{
               
            }];
        }
        else {
            InControlDeviceViewController *controlDeviceVC = [[InControlDeviceViewController alloc] init];
            controlDeviceVC.device = device;
            [self.navigationController pushViewController:controlDeviceVC animated:YES];
        }
    }];
}

- (void)goBack {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)startAnimation {
    [self.searchAnimationTimer setFireDate:[NSDate distantPast]];
}

- (void)stopAnimation {
    [self.searchAnimationTimer setFireDate:[NSDate distantFuture]];
}

- (void)hideAllWating {
    self.waiting1.hidden = YES;
    self.waiting2.hidden = YES;
    self.waiting3.hidden = YES;
}

- (void)animation {
    switch (self.showWating) {
        case 0:
            self.waiting1.hidden = YES;
            self.waiting2.hidden = YES;
            self.waiting3.hidden = YES;
            break;
        case 1:
            self.waiting1.hidden = NO;
            self.waiting2.hidden = YES;
            self.waiting3.hidden = YES;
            break;
        case 2:
            self.waiting1.hidden = NO;
            self.waiting2.hidden = NO;
            self.waiting3.hidden = YES;
            break;
        case 3:
            self.waiting1.hidden = NO;
            self.waiting2.hidden = NO;
            self.waiting3.hidden = NO;
            break;
        default:
            break;
    }
    self.showWating++;
    self.showWating = self.showWating % 4;
    NSLog(@"self.showWating = %zd", self.showWating);
}

- (void)dealloc {
    [self.searchAnimationTimer invalidate];
    self.searchAnimationTimer = nil;
}

@end
