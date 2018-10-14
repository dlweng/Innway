//
//  InAddDeviceStartViewController.m
//  Innway
//
//  Created by danly on 2018/10/1.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InAddDeviceStartViewController.h"
#import "DLCloudDeviceManager.h"
#import "InControlDeviceViewController.h"

@interface InAddDeviceStartViewController ()
@property (weak, nonatomic) IBOutlet UIView *backView;
@end

@implementation InAddDeviceStartViewController

+ (instancetype)addDeviceStartViewController:(BOOL)canBack {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"InAddDevice" bundle:nil];
    InAddDeviceStartViewController *addDeviceStartVC = [sb instantiateViewControllerWithIdentifier:@"InAddDeviceStartViewController"];
    addDeviceStartVC.canBack = canBack;
    return addDeviceStartVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.title = @"Add device";
    self.backView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goBack)];
    [self.backView addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
    NSDictionary *cloudDeviceList = [DLCloudDeviceManager sharedInstance].cloudDeviceList;
    if (cloudDeviceList.count != 0 && !self.canBack) {
        [self pushToControlDeviceController:NO];
    }
    if (cloudDeviceList.count == 0) {
        self.canBack = NO;
    }
    self.backView.hidden = !self.canBack;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setHidden:NO];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"narBarBackgroudImage"] forBarMetrics:UIBarMetricsDefault];
}

- (void)goBack {
    [self pushToControlDeviceController:YES];
}

- (void)pushToControlDeviceController:(BOOL)animation {
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"narBarBackgroudImage"] forBarMetrics:UIBarMetricsDefault];
    InControlDeviceViewController *controlDeviceVC = [[InControlDeviceViewController alloc] init];
    [self.navigationController pushViewController:controlDeviceVC animated:animation];
    [self.navigationController.navigationBar setHidden:NO];
}


@end
