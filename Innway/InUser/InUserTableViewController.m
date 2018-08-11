//
//  InUserTableViewController.m
//  Innway
//
//  Created by danly on 2018/8/4.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InUserTableViewController.h"

@interface InUserTableViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *pwdTextField;
@property (weak, nonatomic) IBOutlet UIButton *hidePwdBtn;

@end

@implementation InUserTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.scrollEnabled = NO;
    self.emailTextField.delegate = self;
    self.pwdTextField.delegate = self;
    [self hidePwdBtnSelected:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 解决在iOS8上会出现tableView往下偏移的问题
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView setContentOffset:CGPointZero animated:NO];
    });
//    CGPointMake(0, -15), iOS8重置密码界面需要这个偏移值才能恢复正常
    
    if (self.email.length == 0 || self.pwd.length == 0) {
//        [self.emailTextField becomeFirstResponder];
    }
    else {
        self.emailTextField.text = self.email;
        self.pwdTextField.text = self.pwd;
    }
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.userViewType == InUserNotPassword) {
        return 1;
    }
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Action
- (IBAction)emailValueChange:(UITextField *)textField {
    if (self.emailValueChanging) {
        self.emailValueChanging(textField.text);
    }
}

- (IBAction)pwdValueChange:(UITextField *)textField {
    if (self.pwdValueChanging) {
        self.pwdValueChanging(textField.text);
    }
}


- (IBAction)emailEditEnd:(UITextField *)textField {
//    if (self.emailValueChanging) {
//        self.emailValueChanging(textField.text);
//    }
}

- (IBAction)passwordEditEnd:(UITextField *)textField {
//    if (self.pwdValueChanging) {
//        self.pwdValueChanging(textField.text);
//    }
}

- (IBAction)hidePwdBtnDidClick:(UIButton *)sender {
    [self hidePwdBtnSelected:!sender.selected];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.emailTextField && self.userViewType == InUserWithPassword) {
        [self.pwdTextField becomeFirstResponder];
    }
    else {
        [self.view endEditing:YES];
    }
    return YES;
}

- (void)hidePwdBtnSelected:(BOOL)selected{
    self.hidePwdBtn.selected = selected;
    if (selected) {
        self.hidePwdBtn.imageView.tintColor = [UIColor blueColor];
        self.pwdTextField.secureTextEntry = NO;
    }
    else {
        self.hidePwdBtn.imageView.tintColor = [UIColor darkGrayColor];
        self.pwdTextField.secureTextEntry = YES;
    }
}

#pragma mark - Properity
- (void)setUserViewType:(InUserViewType)userViewType {
    _userViewType = userViewType;
    [self.tableView reloadData];
}

- (void)setEmail:(NSString *)email {
    _email = email;
    self.emailTextField.text = email;
}

- (void)setPwd:(NSString *)pwd {
    _pwd = pwd;
    self.pwdTextField.text = pwd;
}

@end
