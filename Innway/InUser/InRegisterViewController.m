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
#import "InWebViewController.h"
#import "NSTimer+InTimer.h"

@interface InRegisterViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet InTextField *emailTextField;
@property (weak, nonatomic) IBOutlet InTextField *passwordTextField;
@property (weak, nonatomic) IBOutlet InTextField *verificationCodeTextField;
@property (weak, nonatomic) IBOutlet UIButton *getCodeBtn;
@property (weak, nonatomic) IBOutlet UIButton *agreenBtn;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) int time;


@end

@implementation InRegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Registration";
    self.emailTextField.delegate = self;
    self.passwordTextField.delegate = self;
    self.agreenBtn.selected = NO;
}

- (IBAction)registerBtnDidClick:(UIButton *)sender {
    if (self.emailTextField.text.length == 0) {
        [InAlertView showAlertWithTitle:@"Information" message:@"Email address required" confirmTitle:nil confirmHanler:nil];
        return;
    }
    else if (self.passwordTextField.text.length == 0) {
        [InAlertView showAlertWithTitle:@"Information" message:@"Password required" confirmTitle:nil confirmHanler:nil];
        return;
    }
    else if (self.verificationCodeTextField.text.length == 0) {
        [InAlertView showAlertWithTitle:@"Information" message:@"Verification Code required" confirmTitle:nil confirmHanler:nil];
        return;
    }
    else if (!self.agreenBtn.selected) {
        [InAlertView showAlertWithTitle:@"Information" message:@"同意协议才能注册" confirmTitle:nil confirmHanler:nil];
        return;
    }
    
    [self.view endEditing:YES];
    [InAlertTool showHUDAddedTo:self.view animated:YES];
    NSLog(@"开始注册，邮箱: %@, 密码: %@", self.emailTextField.text, self.passwordTextField.text);
    NSDictionary* body = @{@"username":self.emailTextField.text, @"password":self.passwordTextField.text, @"action":@"register"};
    [InCommon sendHttpMethod:@"POST" URLString:httpDomain body:body completionHandler:^(NSURLResponse *response, NSDictionary *responseObject, NSError * _Nullable error) {
        NSLog(@"注册结果:responseObject = %@, error = %@", responseObject, error);
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        NSInteger code = [responseObject integerValueForKey:@"code" defaultValue:500];
        NSString *messgae;
        
        if (code == 200) {
            messgae = @"Registration success";
        }
        else if (code == 300) {
            messgae = @"Username exists. Please try again";
        }
        else {
            if (error && error.code == -1) {
                messgae = @"Network connection lost";
            }
            else {
                messgae = @"Registration failed";
            }
        }
        [InAlertView showAlertWithTitle:@"Information" message:messgae confirmTitle:nil confirmHanler:nil];
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

- (IBAction)getCodeAction {
    NSLog(@"发送获取验证码的请求");
    self.getCodeBtn.enabled = NO;
    self.time = 0;
    __weak typeof(self) weakSelf = self;
    self.timer = [NSTimer newTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        ++weakSelf.time;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.getCodeBtn setTitle:[NSString stringWithFormat:@"%ds Try again", 60 - self.time] forState:UIControlStateNormal];
            if (weakSelf.time == 60) {
                [weakSelf.getCodeBtn setTitle:@"Get code" forState:UIControlStateNormal];
                weakSelf.getCodeBtn.enabled = YES;
                [weakSelf.timer invalidate];
                weakSelf.timer = nil;
            }
        });
    }];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (IBAction)privacyPolicy {
    NSLog(@"跳转隐私协议");
    InWebViewController *webVC = [[InWebViewController alloc] initWithTitle:@"Privacy Policy" UrlString:@"http://3.16.195.135/PrivacyPolicy/PrivacyPolicy.html"];
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController pushViewController:webVC animated:YES];
    }
}

- (IBAction)agreenBtnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)dealloc {
    NSLog(@"注册界面被销毁");
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
