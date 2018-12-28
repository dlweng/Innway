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
#import "InCommon.h"

@interface InAddDeviceStartViewController ()
@property (weak, nonatomic) IBOutlet UIView *backView;
@end

@implementation InAddDeviceStartViewController

+ (instancetype)addDeviceStartViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"InAddDevice" bundle:nil];
    InAddDeviceStartViewController *addDeviceStartVC = [sb instantiateViewControllerWithIdentifier:@"InAddDeviceStartViewController"];
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
    if (cloudDeviceList.count != 0) {
        [self pushToControlDeviceController:NO];
    }
    self.backView.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setHidden:NO];
    [InCommon setNavgationBar:self.navigationController.navigationBar];
}

- (void)goBack {
    NSLog(@"点击返回键");
    __weak typeof(self) weakSelf = self;
    [InAlertView showAlertWithMessage:@"Exit App?" confirmHanler:^{
        if (weakSelf.navigationController.viewControllers.lastObject == self) {
            [weakSelf.navigationController popViewControllerAnimated:YES];
            [common saveLoginStatus:NO];
        }
    } cancleHanler:nil];
}

- (void)pushToControlDeviceController:(BOOL)animation {
    [InCommon setNavgationBar:self.navigationController.navigationBar];
    InControlDeviceViewController *controlDeviceVC = [[InControlDeviceViewController alloc] init];
    [self.navigationController pushViewController:controlDeviceVC animated:animation];
    [self.navigationController.navigationBar setHidden:NO];
}


@end
