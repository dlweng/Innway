//
//  InRegisterViewController.m
//  Innway
//
//  Created by danly on 2018/8/4.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InRegisterViewController.h"
#import "InTextField.h"
#import "InCommon.h"

@interface InRegisterViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet InTextField *emailTextField;
@property (weak, nonatomic) IBOutlet InTextField *passwordTextField;
//@property (weak, nonatomic) IBOutlet UIButton *registerBtn;


@end

@implementation InRegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Sign up";
    self.emailTextField.delegate = self;
    self.passwordTextField.delegate = self;
//    //设置按钮的圆弧
//    self.registerBtn.layer.masksToBounds = YES;
//    self.registerBtn.layer.cornerRadius = 25;
}

- (IBAction)registerBtnDidClick:(UIButton *)sender {
    if (self.emailTextField.text.length == 0) {
        [InAlertView showAlertWithTitle:@"Information" message:@"请输入邮箱" confirmHanler:nil];
        return;
    }
    else if (self.passwordTextField.text.length == 0) {
        [InAlertView showAlertWithTitle:@"Information" message:@"请输入密码" confirmHanler:nil];
        return;
    }
    
    [self.view endEditing:YES];
    [InAlertTool showHUDAddedTo:self.view animated:YES];
    NSLog(@"开始注册，邮箱: %@, 密码: %@", self.emailTextField.text, self.passwordTextField.text);
    NSDictionary* body = @{@"username":self.emailTextField.text, @"password":self.passwordTextField.text, @"action":@"register"};
    [InCommon sendHttpMethod:@"POST" URLString:httpDomain body:body completionHandler:^(NSURLResponse *response, NSDictionary *responseObject, NSError * _Nullable error) {
        NSLog(@"注册结果:responseObject = %@, error = %@", responseObject, error);
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (error) {
            [InAlertView showAlertWithTitle:@"Information" message:error.localizedDescription confirmHanler:nil];
        }
        else {
//            NSInteger code = [responseObject integerValueForKey:@"code" defaultValue:500];
            NSString *message = [responseObject stringValueForKey:@"message" defaultValue:@"注册失败"];
            [InAlertView showAlertWithTitle:@"Information" message:message confirmHanler:nil];
        }
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.emailTextField) {
        [self.passwordTextField becomeFirstResponder];
    }
    else {
        [self.view endEditing:YES];
    }
    return YES;
}

//- (IBAction)registerBtnDidClick:(UIButton *)sender {
//    if (self.emailTextField.text.length == 0) {
//        [InAlertTool showAlertWithTip:@"请输入邮箱"];
//        return;
//    }
//    else if (self.passwordTextField.text.length == 0) {
//        [InAlertTool showAlertWithTip:@"请输入密码"];
//        return;
//    }
//
//    NSDictionary *parameters = @{@"username":self.emailTextField.text, @"password":self.passwordTextField.text};
//    NSLog(@"开始注册，邮箱: %@, 密码: %@", self.emailTextField.text, self.passwordTextField.text);
//    [[AFHTTPSessionManager manager] POST:@"http://111.230.192.125/user/register" parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
//            NSNumber *code = responseObject[@"code"];
//            NSString *message = responseObject[@"message"];
//            if (code.integerValue == 200) {
//                [InAlertTool showAlertAutoDisappear:@"注册成功"];
//            }
//            else if (code.integerValue == 500) {
//                [InAlertTool showAlertAutoDisappear:[NSString stringWithFormat:@"%@", message]];
//            }
////             NSLog(@"注册结果：code = %@, message = %@", code, message);
//        }
//        NSLog(@"注册结果：task = %@, responseObject = %@", task, responseObject);
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        NSLog(@"注册结果：task = %@, error = %@", task, error);
//        [InAlertTool showAlertAutoDisappear:@"网络连接异常"];
//    }];
//}

@end
