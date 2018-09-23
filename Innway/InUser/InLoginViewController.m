//
//  ViewController.m
//  Innway
//
//  Created by danly on 2018/8/1.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InLoginViewController.h"
#import "InDeviceListViewController.h"
#import <AFNetworking.h>
#import "InAlertTool.h"
#import "InCommon.h"
#import "InAlertTool.h"
#import "InTextField.h"

@interface InLoginViewController ()

@property (weak, nonatomic) IBOutlet UIButton *loginBtn;

@property (weak, nonatomic) IBOutlet InTextField *emailTextField;
@property (weak, nonatomic) IBOutlet InTextField *passwordTextField;
@property (nonatomic, assign) BOOL firstAppear;

@end

@implementation InLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Log in";
    self.firstAppear = YES;
    //    //设置按钮的圆弧
    //    self.loginBtn.layer.masksToBounds = YES;
    //    self.loginBtn.layer.cornerRadius = 25;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.firstAppear && common.ID != -1) {
        self.firstAppear = NO;
        self.emailTextField.text = common.email;
        self.passwordTextField.text = common.pwd;
//        [self userLogin:nil]; // 自动登陆
    }
}

- (IBAction)userLogin:(UIButton *)sender {
    if (self.emailTextField.text.length == 0) {
        [InAlertTool showAlertWithTip:@"请输入邮箱"];
        return;
    }
    else if (self.passwordTextField.text.length == 0) {
        [InAlertTool showAlertWithTip:@"请输入密码"];
        return;
    }
    
    NSLog(@"开始登陆, self.email = %@, self.pwd = %@", self.emailTextField.text, self.passwordTextField.text);
    NSDictionary *parameters = @{@"username":self.emailTextField.text, @"password":self.passwordTextField.text};
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
                    [common saveUserInfoWithID:data[@"id"] email:data[@"username"] pwd:data[@"password"]];
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

@end
