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
#import "InTextField.h"

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
#warning danly-Test
    self.emailTextField.text = @"307262195@qq.com";
    self.passwordTextField.text = @"666888";
    if (self.emailTextField.text.length == 0) {
        [InAlertTool showAlertWithTip:@"请输入邮箱"];
        return;
    }
    else if (self.passwordTextField.text.length == 0) {
        [InAlertTool showAlertWithTip:@"请输入密码"];
        return;
    }

    NSLog(@"开始注册，邮箱: %@, 密码: %@", self.emailTextField.text, self.passwordTextField.text);


    NSDictionary* form = @{@"username":self.emailTextField.text, @"password":self.passwordTextField.text, @"action":@"register"};

    NSMutableURLRequest* formRequest = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST" URLString:@"http://121.12.125.214:1050/GetData.ashx" parameters:form error:nil];

    [formRequest setValue:@"application/x-www-form-urlencoded; charset=utf-8"forHTTPHeaderField:@"Content-Type"];

    AFHTTPSessionManager*manager = [AFHTTPSessionManager manager];

    AFJSONResponseSerializer* responseSerializer = [AFJSONResponseSerializer serializer];

    [responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"application/json",@"text/json",@"text/javascript",@"text/html",@"text/plain",nil]];

    manager.responseSerializer= responseSerializer;

    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:formRequest uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse *_Nonnull response,id _Nullable responseObject,NSError *_Nullable error) {

        if(error) {

            NSLog(@"Error: %@", error);

            return;

        }

        NSLog(@"%@ %@", responseObject, responseObject[@"message"]);

    }];

    [dataTask resume];
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.emailTextField) {
        [self.passwordTextField becomeFirstResponder];
    }
    else {
        [self.view endEditing:YES];
    }
    return YES;
}

@end
