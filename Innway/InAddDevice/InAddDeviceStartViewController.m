//
//  InAddDeviceStartViewController.m
//  Innway
//
//  Created by danly on 2018/10/1.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InAddDeviceStartViewController.h"

@interface InAddDeviceStartViewController ()
@property (nonatomic, assign) BOOL canBack;
@end

@implementation InAddDeviceStartViewController

+ (instancetype)addDeviceStartViewController:(BOOL)canBack {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"InAddDevice" bundle:nil];
    InAddDeviceStartViewController *addDeviceStartVC = [sb instantiateViewControllerWithIdentifier:@"InAddDeviceStartViewController"];
    return addDeviceStartVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.title = @"Add device";

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setHidden:NO];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"narBarBackgroudImage"] forBarMetrics:UIBarMetricsDefault];
}

//- (IBAction)addDeviceBtnClick {
//    NSLog(@"点击添加设备按钮");
//}



@end
