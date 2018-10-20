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
    
    if ([UIScreen mainScreen].bounds.size.width != 320) {
        self.lineTopConstraint.constant = 25;
    }
}

- (void)setupNarBar {
    self.navigationController.navigationBar.hidden = NO;
    self.navigationItem.title = @"Change password";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
}

- (IBAction)changePasswordDidClick {
    NSLog(@"修改密码");
    NSLog(@"旧密码：%@， 新密码：%@， 确认密码：%@", self.oldPwd, self.pwdNew, self.confirmPwd);
    [InAlertView showAlertWithTitle:@"Information" message:@"暂未支持" confirmHanler:nil];
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
