//
//  ViewController.m
//  Innway
//
//  Created by danly on 2018/8/1.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InLoginViewController.h"
#import "InUserTableViewController.h"
#import "InDeviceListViewController.h"
#import <AFNetworking.h>
#import "InAlertTool.h"
#import "InCommon.h"
#import "InAlertTool.h"

@interface InLoginViewController ()

@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *pwd;
@property (nonatomic, strong) InCommon *common;
@property (nonatomic, weak) InUserTableViewController *userTableViewVC;
@property (nonatomic, assign) BOOL firstAppear;

@end

@implementation InLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Log in";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    //设置按钮的圆弧
    self.loginBtn.layer.masksToBounds = YES;
    self.loginBtn.layer.cornerRadius = 25;
    self.firstAppear = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.firstAppear && self.common.ID != -1) {
        self.firstAppear = NO;
        self.userTableViewVC.email = self.common.email;
        self.userTableViewVC.pwd = self.common.pwd;
        self.email = self.common.email;
        self.pwd = self.common.pwd;
        [self userLogin:nil]; // 自动登陆
    }
}

- (void)goBack {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)userLogin:(UIButton *)sender {
    if (self.email.length == 0) {
        [InAlertTool showAlertWithTip:@"请输入邮箱"];
        return;
    }
    else if (self.pwd.length == 0) {
        [InAlertTool showAlertWithTip:@"请输入密码"];
        return;
    }
    
    NSLog(@"开始登陆, self.email = %@, self.pwd = %@", self.email, self.pwd);
    NSDictionary *parameters = @{@"username":self.email, @"password":self.pwd};
    [InAlertTool showHUDAddedTo:self.view animated:YES];
    [[AFHTTPSessionManager manager] POST:@"http://111.230.192.125/user/login" parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"登陆结果：task = %@, responseObject = %@", task, responseObject);
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSNumber *code = responseObject[@"code"];
            NSString *message = responseObject[@"message"];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if (code.integerValue == 200) {
                NSDictionary *data = responseObject[@"data"];
                if (data) {
                    [self.common saveUserInfoWithID:data[@"id"] email:data[@"username"] pwd:data[@"password"]];
                }
//                [InAlertTool showAlertAutoDisappear:@"登陆成功" completion:^{
                [self pushToDeviceListController];
//                }];
            }
            else if (code.integerValue == 500) {
                [InAlertTool showAlertAutoDisappear:[NSString stringWithFormat:@"%@", message]];
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"登陆结果：task = %@, error = %@", task, error);
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [InAlertTool showAlertAutoDisappear:@"网络连接异常"];
    }];
}

- (void)pushToDeviceListController {
    InDeviceListViewController *deviceListController = [[InDeviceListViewController alloc] initWithStyle:UITableViewStylePlain];
    [self.navigationController pushViewController:deviceListController animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[InUserTableViewController class]]) {
        InUserTableViewController *userTableViewVC = segue.destinationViewController;
        self.userTableViewVC = userTableViewVC;
        userTableViewVC.userViewType = InUserWithPassword;
        userTableViewVC.emailValueChanging = ^(NSString *email) {
            self.email = email;
//            NSLog(@"邮箱: %@", self.email);
        };
        userTableViewVC.pwdValueChanging = ^(NSString *pwd) {
            self.pwd = pwd;
//            NSLog(@"密码: %@", self.pwd);
        };
    }
}

- (InCommon *)common {
    return [InCommon sharedInstance];
}



@end
