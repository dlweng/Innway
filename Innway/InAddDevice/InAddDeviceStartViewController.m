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
@property (nonatomic, assign) BOOL canBack;
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
    self.backView.hidden = !self.canBack;
    if (!self.canBack) {
        if ([DLCloudDeviceManager sharedInstance].cloudDeviceList.count > 0) {
            [self pushToControlDeviceController];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setHidden:NO];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"narBarBackgroudImage"] forBarMetrics:UIBarMetricsDefault];
}

- (void)goBack {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)pushToControlDeviceController {
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"narBarBackgroudImage"] forBarMetrics:UIBarMetricsDefault];
    InControlDeviceViewController *controlDeviceVC = [[InControlDeviceViewController alloc] init];
    [self.navigationController pushViewController:controlDeviceVC animated:NO];
    [self.navigationController.navigationBar setHidden:NO];
}


@end
