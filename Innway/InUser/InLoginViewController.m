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

@interface InLoginViewController ()

@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *pwd;

@end

@implementation InLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //设置按钮的圆弧
    self.loginBtn.layer.masksToBounds = YES;
    self.loginBtn.layer.cornerRadius = 25;
}

- (IBAction)userLogin:(UIButton *)sender {
    NSLog(@"开始登陆, self.email = %@, self.pwd = %@", self.email, self.pwd);
    NSDictionary *parameters = @{@"username":self.email, @"password":self.pwd};
    [[AFHTTPSessionManager manager] POST:@"http://111.230.192.125/user/login" parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSNumber *code = responseObject[@"code"];
            NSString *message = responseObject[@"message"];
            if (code.integerValue == 200) {
                [InAlertTool showAlertAutoDisappear:@"登陆成功" completion:^{
                    [self pushToDeviceListController];
                }];
            }
            else if (code.integerValue == 500) {
                [InAlertTool showAlertAutoDisappear:[NSString stringWithFormat:@"%@", message]];
            }
        }
        NSLog(@"登陆结果：task = %@, responseObject = %@", task, responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"登陆结果：task = %@, error = %@", task, error);
        [InAlertTool showAlertAutoDisappear:@"登陆失败"];
    }];
#if DEBUG
    [self pushToDeviceListController];
#endif
}

- (void)pushToDeviceListController {
    InDeviceListViewController *deviceListController = [[InDeviceListViewController alloc] initWithStyle:UITableViewStylePlain];
    [self.navigationController pushViewController:deviceListController animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[InUserTableViewController class]]) {
        InUserTableViewController *userTableViewVC = segue.destinationViewController;
//        userTableViewVC.email = @"邮箱";
//        userTableViewVC.pwd = @"密码";
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




@end
