//
//  ViewController.m
//  Innway
//
//  Created by danly on 2018/8/1.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InCommon.h"
#import "InTextField.h"
#import "InLoginViewController.h"
#import "InDeviceListViewController.h"

@interface InLoginViewController ()<UITextFieldDelegate>

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
    self.emailTextField.delegate = self;
    self.passwordTextField.delegate = self;
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
        [self userLogin:nil]; // 自动登陆
    }
    
    [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setBarTintColor:[UIColor blackColor]];
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
    
    [self.view endEditing:YES];
    [InAlertTool showHUDAddedTo:self.view animated:YES];
    NSDictionary* body = @{@"username":self.emailTextField.text, @"password":self.passwordTextField.text, @"action":@"login"};
    [InCommon sendHttpMethod:@"POST" URLString:@"http://121.12.125.214:1050/GetData.ashx" body:body completionHandler:^(NSURLResponse *response, NSDictionary *responseObject, NSError * _Nullable error) {
        NSLog(@"登陆结果:responseObject = %@, error = %@", responseObject, error);
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (error) {
            [InAlertTool showAlertAutoDisappear:error.localizedDescription];
        }
        else {
            NSInteger code = [responseObject integerValueForKey:@"code" defaultValue:500];
            if (code == 200) {
                NSDictionary *data = [responseObject dictValueForKey:@"data" defaultValue:nil];
                if (data) {
                    NSInteger ID = [data integerValueForKey:@"ID" defaultValue:-1];
                    NSString *userName = [data stringValueForKey:@"LoginName" defaultValue:@""];
                    NSString *password = [data stringValueForKey:@"PassWord" defaultValue:@""];
                    [common saveUserInfoWithID:ID email:userName pwd:password];
                }
                [self pushToDeviceListController];
            }
            else {
                NSString *message = [responseObject stringValueForKey:@"message" defaultValue:@"登陆失败"];
                [InAlertTool showAlertAutoDisappear:message];
            }
            
        }
    }];
}

- (void)pushToDeviceListController {
    InDeviceListViewController *deviceListController = [[InDeviceListViewController alloc] initWithStyle:UITableViewStylePlain];
    [self.navigationController pushViewController:deviceListController animated:YES];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"narBarBackgroudImage"] forBarMetrics:UIBarMetricsDefault];
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

@end
