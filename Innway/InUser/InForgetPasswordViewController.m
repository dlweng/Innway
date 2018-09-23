//
//  InForgetPasswordViewController.m
//  Innway
//
//  Created by danly on 2018/8/4.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InForgetPasswordViewController.h"
#import "InUserTableViewController.h"
#import <AFNetworking.h>
#import "InAlertTool.h"

@interface InForgetPasswordViewController ()

@property (weak, nonatomic) IBOutlet UIButton *resetBtn;
@property (nonatomic, copy) NSString *email;

@end

@implementation InForgetPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Retrieve password";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    
    //设置按钮的圆弧
    self.resetBtn.layer.masksToBounds = YES;
    self.resetBtn.layer.cornerRadius = 25;
}

- (void)goBack {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)resetBtnDidClick:(UIButton *)sender {
    if (self.email.length == 0) {
        [InAlertTool showAlertWithTip:@"请输入邮箱"];
        return;
    }
    
    NSLog(@"重置密码, 邮箱:%@", self.email);
    NSDictionary *parameters = @{@"username":self.email};
    [[AFHTTPSessionManager manager] POST:@"http://111.230.192.125/user/sendResetEmail" parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSNumber *code = responseObject[@"code"];
            NSString *message = responseObject[@"message"];
            if (code.integerValue == 200) {
                [InAlertTool showAlertAutoDisappear:@"重置成功"];
            }
            else if (code.integerValue == 500) {
                [InAlertTool showAlertAutoDisappear:[NSString stringWithFormat:@"%@", message]];
            }
//            NSLog(@"重置结果：code = %@, message = %@", code, message);
        }
        NSLog(@"重置结果：task = %@, responseObject = %@", task, responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"重置结果：task = %@, error = %@", task, error);
        [InAlertTool showAlertAutoDisappear:@"网络连接异常"];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[InUserTableViewController class]]) {
        InUserTableViewController *userTableViewVC = segue.destinationViewController;
        userTableViewVC.userViewType = InUserNotPassword;
        userTableViewVC.emailValueChanging = ^(NSString *email) {
            self.email = email;
            NSLog(@"邮箱: %@", self.email);
        };
    }
}

@end
