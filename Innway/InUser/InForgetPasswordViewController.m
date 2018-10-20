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
    if (self.emailTextField.text.length == 0) {
        [InAlertView showAlertWithTitle:@"Information" message:@"请输入邮箱" confirmHanler:nil];
        return;
    }
    [self.view endEditing:YES];
    NSLog(@"重置密码, 邮箱:%@", self.emailTextField.text);
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
