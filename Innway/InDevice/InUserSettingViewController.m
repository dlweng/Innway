//
//  InUserSettingViewController.m
//  Innway
//
//  Created by danly on 2018/8/5.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InUserSettingViewController.h"
#import "InCommon.h"
#import "DLCloudDeviceManager.h"
#import "InAlarmTypeSelectionView.h"
#define InSettingViewCellReuseIdentifier @"InSettingViewCell"

@interface InUserSettingViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UISwitch *locationBtn;
@property (nonatomic, strong) UISwitch *flashBtn;
@property (weak, nonatomic) IBOutlet UIButton *logoutBtn;
@property (nonatomic, assign) CGPoint perPoint;
@property (nonatomic, assign) CGPoint movePoint;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topBodyViewHeigthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *userIconCenterYConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *btnTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topBodyHeightConstraint;


@end

@implementation InUserSettingViewController

//+ (instancetype)UserSettingViewController {
//    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"InUserSettingViewController" bundle:nil];
//    return sb.instantiateInitialViewController;
//}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:InSettingViewCellReuseIdentifier];
    self.tableView.scrollEnabled = NO;
    
    [self addLocationBtn];
    [self addFlashBtn];
    
    self.logoutBtn.layer.masksToBounds = YES;
    self.logoutBtn.layer.cornerRadius = 10;
    self.emailLabel.text = common.email;
    self.userNameLabel.text = @"User";
    
    if ([InCommon isIPhoneX]) {
        self.userIconCenterYConstraint.constant += 20;
        self.topBodyViewHeigthConstraint.constant += 20;
    }
    
    if ([UIScreen mainScreen].bounds.size.height == 568) {
        self.btnTopConstraint.constant = 15;
        self.topBodyHeightConstraint.constant = 110;
    }
}

#pragma mark - Action
- (IBAction)changeUserIcon {
    NSLog(@"更换头像");
}

- (void)addLocationBtn {
    UISwitch *btn = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
    [btn addTarget:self action:@selector(locationBtnDidClick) forControlEvents:UIControlEventValueChanged];
    self.locationBtn = btn;
}

- (void)addFlashBtn {
    self.flashBtn = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
    [self.flashBtn addTarget:self action:@selector(flashBtnDidClick:) forControlEvents:UIControlEventValueChanged];
}

- (void)locationBtnDidClick {
    NSLog(@"按钮被点击, %d", self.locationBtn.isOn);
    if ([self.delegate respondsToSelector:@selector(settingViewController:showUserLocation:)]) {
        [self.delegate settingViewController:self showUserLocation:self.locationBtn.isOn];
    }
}

- (void)flashBtnDidClick:(UISwitch *)btn {
    NSLog(@"闪光灯按钮被点击: %d", btn.isOn);
    [common saveFlashStatus:btn.isOn];
}

// 注销账户
- (IBAction)logout{
    NSLog(@"退出账户");
//    [[InCommon sharedInstance] clearUserInfo];
    [common saveLoginStatus:NO];
    if (self.logoutUser) {
        // 清除云端列表
        [[DLCloudDeviceManager sharedInstance] deleteCloudList];
        self.logoutUser();
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 7;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:InSettingViewCellReuseIdentifier];
    cell.textLabel.textColor = [UIColor colorWithRed:51.0/255.0 green:51.0/255.0 blue:51.0/255.0 alpha:1];
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Change Password";
            break;
        case 1:
            cell.textLabel.text = @"Buy an Innway";
            break;
        case 2:
            cell.textLabel.text = @"Help Center";
            break;
        case 3:
            cell.textLabel.text = @"Contact Innway";
            break;
        case 4:
            cell.textLabel.text = @"Privacy Policy";
            break;
        case 5: {
            cell.textLabel.text = @"Flash Light";
            cell.accessoryView = self.flashBtn;
            self.flashBtn.on = [common flashStatus];
            break;
        }
        case 6:{
            cell.textLabel.text = @"Display Phone Location";
            self.locationBtn.on = [common getIsShowUserLocation];
            cell.accessoryView = self.locationBtn;
            break;
        }
        default:
            break;
    }
    return cell;
}

//// 下面两个方法都必须设置，才能成功设置分组头的值
//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    if (section == 0) {
//        NSString *email = @"8888888@qq.com";
//        return [NSString stringWithFormat:@"   用户: %@", email];
//    }
//    return nil;
//}
//
//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    if (section == 0) {
//        UILabel *label = [[UILabel alloc] init];
//        NSString *email = [InCommon sharedInstance].email;
//        label.text = [NSString stringWithFormat:@"   用户: %@", email];
//        label.font = [UIFont systemFontOfSize:16.0];
//        label.textColor = [UIColor darkGrayColor];
//        return label;
//    }
//    return nil;
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self.delegate respondsToSelector:@selector(settingViewController:didSelectRow:)]) {
        [self.delegate settingViewController:self didSelectRow:indexPath.row];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint originLocation = [touch locationInView:self.view];
    self.perPoint = originLocation;
    NSLog(@"originLocation = %@", [NSValue valueWithCGPoint:originLocation]);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"touches.count = %zd", touches.count);
    UITouch *touch = [touches anyObject];
    CGPoint currentLocation = [touch locationInView:self.view];
    NSLog(@"perPoint = %@", [NSValue valueWithCGPoint:self.perPoint]);
    NSLog(@"currentLocation = %@", [NSValue valueWithCGPoint:currentLocation]);
    CGPoint movePoint = CGPointMake(self.movePoint.x + self.perPoint.x - currentLocation.x, self.perPoint.y - currentLocation.y);
    self.perPoint = currentLocation;
    self.movePoint = movePoint;
    NSLog(@"movePoint = %@", [NSValue valueWithCGPoint:movePoint]);
    if ([self.delegate respondsToSelector:@selector(settingViewController:touchMove:)]) {
        [self.delegate settingViewController:self touchMove:movePoint];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint currentLocation = [touch locationInView:self.view];
    CGPoint movePoint = CGPointMake(self.perPoint.x - currentLocation.x, self.perPoint.y - currentLocation.y);
    self.perPoint = currentLocation;
    NSLog(@"movePoint = %@", [NSValue valueWithCGPoint:movePoint]);
    if ([self.delegate respondsToSelector:@selector(settingViewController:touchEnd:)]) {
        [self.delegate settingViewController:self touchEnd:movePoint];
    }
}



@end
