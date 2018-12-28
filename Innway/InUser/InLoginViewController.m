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
#import "InControlDeviceViewController.h"
#import "InAddDeviceStartViewController.h"
#import "DLCloudDeviceManager.h"

@interface InLoginViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *loginBtn;

@property (weak, nonatomic) IBOutlet InTextField *emailTextField;
@property (weak, nonatomic) IBOutlet InTextField *passwordTextField;

@end

@implementation InLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Log in";
    self.emailTextField.delegate = self;
    self.passwordTextField.delegate = self;
    //    //设置按钮的圆弧
    //    self.loginBtn.layer.masksToBounds = YES;
    //    self.loginBtn.layer.cornerRadius = 25;
    if (common.ID != -1) {
        self.emailTextField.text = common.email;
        self.passwordTextField.text = common.pwd;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    BOOL login = [common getLoginStatus];
    if (common.ID != -1 && login) {
        [self userLogin:nil]; // 自动登陆
    }
    [self.navigationController.navigationBar setHidden:NO];
    [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setBarTintColor:[UIColor blackColor]];
}

- (IBAction)userLogin:(UIButton *)sender {
    if (self.emailTextField.text.length == 0) {
        [InAlertView showAlertWithTitle:@"Information" message:@"Email address required" confirmTitle:nil confirmHanler:nil];
        return;
    }
    else if (self.passwordTextField.text.length == 0) {
        [InAlertView showAlertWithTitle:@"Information" message:@"Password required" confirmTitle:nil confirmHanler:nil];
        return;
    }
    
    [self.view endEditing:YES];
    [InAlertTool showHUDAddedTo:self.view animated:YES];
    
    NSDictionary* body = @{@"username":self.emailTextField.text, @"password":self.passwordTextField.text, @"action":@"login"};
    [InCommon sendHttpMethod:@"POST" URLString:httpDomain body:body completionHandler:^(NSURLResponse *response, NSDictionary *responseObject, NSError * _Nullable error) {
        NSLog(@"登陆结果:responseObject = %@, error = %@", responseObject, error);
        NSInteger code = [responseObject integerValueForKey:@"code" defaultValue:500];
        if (code == 200) {
            NSDictionary *data = [responseObject dictValueForKey:@"data" defaultValue:nil];
            if (data) {
                NSInteger ID = [data integerValueForKey:@"ID" defaultValue:-1];
                NSString *userName = [data stringValueForKey:@"LoginName" defaultValue:@""];
                NSString *password = [data stringValueForKey:@"PassWord" defaultValue:@""];
                [common saveUserInfoWithID:ID email:userName pwd:password];
                [common saveLoginStatus:YES];
            }
            [self pushToNewCotroller];
        }
        else {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            // 如果实在后台，只有是通过iBeacon激活的才有可能，直接跳过
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                if (common.email.length > 0 && common.pwd.length > 0) {
                    [self pushToNewCotroller];
                    return ;
                }
            }
            NSString *message;
            if (code == 300) {
                message = @"Wrong username or password";
            }
            else  {
                if (error && error.code == -1) {
                    message = @"Network connection lost";
                }
                else {
                    message = @"Login failed";
                }
            }
            [InAlertView showAlertWithTitle:@"Information" message:message confirmTitle:nil confirmHanler:nil];
        }
    }];
}

- (void)pushToNewCotroller {
    // 获取云端设备列表
    [[DLCloudDeviceManager sharedInstance] getHTTPCloudDeviceListCompletion:^(DLCloudDeviceManager *manager, NSDictionary *cloudList) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (cloudList.count == 0) {
            [self pushToAddDeviceController:YES];
        }
        else {
            [self pushToAddDeviceController:NO];
        }
    }];
}

- (void)pushToControlDeviceController {
    [InCommon setNavgationBar:self.navigationController.navigationBar];
    InControlDeviceViewController *controlDeviceVC = [[InControlDeviceViewController alloc] init];
    [self.navigationController pushViewController:controlDeviceVC animated:YES];
    [self.navigationController.navigationBar setHidden:NO];
}
    
- (void)pushToAddDeviceController:(BOOL)animation {
    InAddDeviceStartViewController *addDeviceStartVC = [InAddDeviceStartViewController addDeviceStartViewController];
    [self.navigationController pushViewController:addDeviceStartVC animated:animation];
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
