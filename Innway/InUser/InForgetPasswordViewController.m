//
//  InForgetPasswordViewController.m
//  Innway
//
//  Created by danly on 2018/8/4.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InForgetPasswordViewController.h"
#import "InTextField.h"
#import "InCommon.h"

@interface InForgetPasswordViewController ()<UITextFieldDelegate>

//@property (weak, nonatomic) IBOutlet UIButton *resetBtn;
@property (weak, nonatomic) IBOutlet InTextField *emailTextField;

@end

@implementation InForgetPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Reset password";
    self.emailTextField.delegate = self;
//    //设置按钮的圆弧
//    self.resetBtn.layer.masksToBounds = YES;
//    self.resetBtn.layer.cornerRadius = 25;
}

- (IBAction)resetBtnDidClick:(UIButton *)sender {
    NSString *email = self.emailTextField.text;
    if (email.length == 0) {
        [InAlertView showAlertWithTitle:@"Information" message:@"Email address required" confirmTitle:nil confirmHanler:nil];
        return;
    }
    [self.view endEditing:YES];
    NSLog(@"发送重置密码邮件:%@", email);
    [InAlertView showAlertWithTitle:@"Email sent" message:@"Check your email for an email containing the link to reset your password." confirmTitle:@"OK" confirmHanler:^{
        // 发送重置密码邮件
        [InAlertTool showHUDAddedTo:self.view animated:YES];
        NSDictionary* body = @{@"LoginName":email, @"action":@"sendResetEmailByLoginName"};
        [InCommon sendHttpMethod:@"POST" URLString:httpDomain body:body completionHandler:^(NSURLResponse *response, NSDictionary *responseObject, NSError * _Nullable error) {
            NSLog(@"发送重置密码邮件结果:responseObject = %@, error = %@", responseObject, error);
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            NSInteger code = [responseObject integerValueForKey:@"code" defaultValue:500];
            if (code == 200) {
                NSLog(@"发送重置密码邮件成功");
                [InAlertView showAlertWithTitle:@"Information" message:@"Reset password email sent" confirmTitle:nil confirmHanler:nil];
            }
            else {
                NSString *message;
                if (code == 300) {
                    message = @"No such email address";
                }
                else {
                    if (error && error.code == -1) {
                        message = @"Network connection lost";
                    }
                    else {
                        message = @"Reset password email failed to send";
                    }
                }
                [InAlertView showAlertWithTitle:@"Information" message:message confirmTitle:nil confirmHanler:nil];
            }
        }];
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    return YES;
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

@end
