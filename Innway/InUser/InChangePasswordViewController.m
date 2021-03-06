//
//  InChangePasswordViewController.m
//  Innway
//
//  Created by danly on 2018/10/14.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InChangePasswordViewController.h"
#import "InCommon.h"
#import "InChangePasswordCell.h"

@interface InChangePasswordViewController () <InChangePasswordCellDelegate, UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, copy) NSString *oldPwd;
@property (nonatomic, copy) NSString *pwdNew;
@property (nonatomic, copy) NSString *confirmPwd;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lineTopConstraint;

@end

@implementation InChangePasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNarBar];
    [self.tableView registerNib:[UINib nibWithNibName:@"InChangePasswordCell" bundle:nil] forCellReuseIdentifier:@"InChangePasswordCell"];
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard)]];
    self.tableView.bounces = YES;
    if ([UIDevice currentDevice].systemVersion.integerValue < 11) {
        self.lineTopConstraint.constant = 80;
    }
}

- (void)setupNarBar {
    self.navigationController.navigationBar.hidden = NO;
    self.navigationItem.title = @"Change Password";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
}

- (IBAction)changePasswordDidClick {
    NSLog(@"修改密码");
    NSLog(@"旧密码：%@， 新密码：%@， 确认密码：%@", self.oldPwd, self.pwdNew, self.confirmPwd);
    if (self.oldPwd.length == 0) {
        [InAlertView showAlertWithTitle:@"Information" message:@"Old password cannot be blank" confirmTitle:nil confirmHanler:nil];
    }
    else if (self.pwdNew.length == 0) {
        [InAlertView showAlertWithTitle:@"Information" message:@"New password cannot be blank" confirmTitle:nil confirmHanler:nil];
    }
    else if (self.confirmPwd.length == 0) {
        [InAlertView showAlertWithTitle:@"Information" message:@"Password confirmation cannot be blank" confirmTitle:nil confirmHanler:nil];
    }
    else {
        if (![self.pwdNew isEqualToString:self.confirmPwd]) {
            [InAlertView showAlertWithTitle:@"Information" message:@"New password and password confirmation do not match" confirmTitle:nil confirmHanler:nil];
        }
        else {
            [InAlertTool showHUDAddedTo:self.view animated:YES];
            NSDictionary *body = @{@"action":@"updatePassword", @"Uid":[NSString stringWithFormat:@"%zd", [InCommon sharedInstance].ID], @"Oldpassword":self.oldPwd, @"Newpassword":self.pwdNew};
            [InCommon sendHttpMethod:@"POST" URLString:httpDomain body:body completionHandler:^(NSURLResponse *response, NSDictionary *responseObject, NSError * _Nullable error) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                NSInteger code = [responseObject integerValueForKey:@"code" defaultValue:500];
                if (code == 200) {
                    [InAlertView showAlertWithTitle:@"Information" message:@"Password changed" confirmTitle:nil confirmHanler:nil];
                }
                else {
                    NSString *message;
                    if (code == 300) {
                        message = @"Device not found";
                    }
                    else {
                        if (error && error.code == -1) {
                            message = @"Network connection lost";
                        }
                        else {
                             message = @"Password change failure";
                        }
                    }
                    [InAlertView showAlertWithTitle:@"Information" message:message confirmTitle:nil confirmHanler:nil];
                }
            }];
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    InChangePasswordCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InChangePasswordCell"];
    cell.indexPath = indexPath;
    cell.delegate = self;
    switch (indexPath.row) {
        case 0:
            cell.placeHolder = @"Old password";
            break;
        case 1:
            cell.placeHolder = @"New password";
            break;
        case 2:
            cell.placeHolder = @"Confirm the new password";
            break;
        default:
            break;
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)changePasswordCell:(InChangePasswordCell *)cell pwd:(NSString *)pwd {
    switch (cell.indexPath.row) {
        case 0:
            self.oldPwd = pwd;
            break;
        case 1:
            self.pwdNew = pwd;
            break;
        case 2:
            self.confirmPwd = pwd;
            break;
        default:
            break;
    }
}

- (void)changePasswordCellShouldReturn:(InChangePasswordCell *)cell {
    switch (cell.indexPath.row) {
        case 0:
        {
            InChangePasswordCell *newPwdCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            [newPwdCell.pwdTextField becomeFirstResponder];
            break;
        }
        case 1: {
            InChangePasswordCell *confirmPwdCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
            [confirmPwdCell.pwdTextField becomeFirstResponder];
            break;
        }
        default:
            [self.view endEditing:YES];
            break;
    }
}

- (void)hideKeyBoard {
    [self.view endEditing:YES];
}

- (void)goBack {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
