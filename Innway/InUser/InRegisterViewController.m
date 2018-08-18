//
//  InRegisterViewController.m
//  Innway
//
//  Created by danly on 2018/8/4.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InRegisterViewController.h"
#import "InUserTableViewController.h"
#import <AFNetworking.h>
#import "InAlertTool.h"

@interface InRegisterViewController ()

@property (weak, nonatomic) IBOutlet UIButton *registerBtn;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *pwd;

@end

@implementation InRegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"注册账户";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    
    //设置按钮的圆弧
    self.registerBtn.layer.masksToBounds = YES;
    self.registerBtn.layer.cornerRadius = 25;
}

- (void)goBack {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)registerBtnDidClick:(UIButton *)sender {
    if (self.email.length == 0) {
        [InAlertTool showAlertWithTip:@"请输入邮箱"];
        return;
    }
    else if (self.pwd.length == 0) {
        [InAlertTool showAlertWithTip:@"请输入密码"];
        return;
    }
    
    NSDictionary *parameters = @{@"username":self.email, @"password":self.pwd};
    NSLog(@"开始注册，邮箱: %@, 密码: %@", self.email, self.pwd);
    [[AFHTTPSessionManager manager] POST:@"http://111.230.192.125/user/register" parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSNumber *code = responseObject[@"code"];
            NSString *message = responseObject[@"message"];
            if (code.integerValue == 200) {
                [InAlertTool showAlertAutoDisappear:@"注册成功"];
            }
            else if (code.integerValue == 500) {
                [InAlertTool showAlertAutoDisappear:[NSString stringWithFormat:@"%@", message]];
            }
//             NSLog(@"注册结果：code = %@, message = %@", code, message);
        }
        NSLog(@"注册结果：task = %@, responseObject = %@", task, responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"注册结果：task = %@, error = %@", task, error);
        [InAlertTool showAlertAutoDisappear:@"注册失败"];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[InUserTableViewController class]]) {
        InUserTableViewController *userTableViewVC = segue.destinationViewController;
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
