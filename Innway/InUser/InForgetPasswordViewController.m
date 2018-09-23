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
#import "InTextField.h"

@interface InForgetPasswordViewController ()<UITextFieldDelegate>

//@property (weak, nonatomic) IBOutlet UIButton *resetBtn;
@property (weak, nonatomic) IBOutlet InTextField *emailTextField;

@end

@implementation InForgetPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Retrieve password";
    self.emailTextField.delegate = self;
//    //设置按钮的圆弧
//    self.resetBtn.layer.masksToBounds = YES;
//    self.resetBtn.layer.cornerRadius = 25;
}

- (IBAction)resetBtnDidClick:(UIButton *)sender {
    [self.view endEditing:YES];
    if (self.emailTextField.text.length == 0) {
        [InAlertTool showAlertWithTip:@"请输入邮箱"];
        return;
    }
    
    NSLog(@"重置密码, 邮箱:%@", self.emailTextField.text);
    NSDictionary *parameters = @{@"username":self.emailTextField.text};
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

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([segue.destinationViewController isKindOfClass:[InUserTableViewController class]]) {
//        InUserTableViewController *userTableViewVC = segue.destinationViewController;
//        userTableViewVC.userViewType = InUserNotPassword;
//        userTableViewVC.emailValueChanging = ^(NSString *email) {
//            self.email = email;
//            NSLog(@"邮箱: %@", self.email);
//        };
//    }
//}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    return YES;
}

@end
