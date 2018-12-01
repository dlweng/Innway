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
    self.navigationItem.title = @"Retrieve password";
    self.emailTextField.delegate = self;
//    //设置按钮的圆弧
//    self.resetBtn.layer.masksToBounds = YES;
//    self.resetBtn.layer.cornerRadius = 25;
}

- (IBAction)resetBtnDidClick:(UIButton *)sender {
    NSString *email = self.emailTextField.text;
    if (email == 0) {
        [InAlertView showAlertWithTitle:@"Information" message:@"请输入邮箱" confirmHanler:nil];
        return;
    }
    [self.view endEditing:YES];
    NSLog(@"发送重置密码邮件:%@", email);
    [InAlertView showAlertWithTitle:@"Information" message:@"An email has been sent to the provided email with further instructions." confirmHanler:^{
        // 发送重置密码邮件
        [InAlertTool showHUDAddedTo:self.view animated:YES];
        NSDictionary* body = @{@"LoginName":email, @"action":@"sendResetEmailByLoginName"};
        [InCommon sendHttpMethod:@"POST" URLString:httpDomain body:body completionHandler:^(NSURLResponse *response, NSDictionary *responseObject, NSError * _Nullable error) {
            NSLog(@"发送重置密码邮件结果:responseObject = %@, error = %@", responseObject, error);
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if (error) {
                [InAlertView showAlertWithTitle:@"Information" message:error.localizedDescription confirmHanler:nil];
            }
            else {
                NSInteger code = [responseObject integerValueForKey:@"code" defaultValue:500];
                if (code == 200) {
                    NSLog(@"发送重置密码邮件成功");
                    [InAlertView showAlertWithTitle:@"Information" message:@"发送重置密码邮件成功" confirmHanler:nil];
                }
                else {
                    NSString *message = [responseObject stringValueForKey:@"message" defaultValue:@"发送重置密码邮件失败"];
                    [InAlertView showAlertWithTitle:@"Information" message:message confirmHanler:nil];
                }
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
