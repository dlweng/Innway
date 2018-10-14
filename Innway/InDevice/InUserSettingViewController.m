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
#define InSettingViewCellReuseIdentifier @"InSettingViewCell"

@interface InUserSettingViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UISwitch *locationBtn;
@property (weak, nonatomic) IBOutlet UIButton *logoutBtn;
@property (nonatomic, assign) CGPoint perPoint;
@property (nonatomic, assign) CGPoint movePoint;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topBodyViewHeigthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *userIconCenterYConstraint;


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
    
    self.logoutBtn.layer.masksToBounds = YES;
    self.logoutBtn.layer.cornerRadius = 10;
    self.emailLabel.text = common.email;
    self.userNameLabel.text = @"Danly";
    
    if ([InCommon isIPhoneX]) {
        self.userIconCenterYConstraint.constant += 20;
        self.topBodyViewHeigthConstraint.constant += 20;
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

- (void)locationBtnDidClick {
    NSLog(@"按钮被点击, %d", self.locationBtn.isOn);
}

// 注销账户
- (IBAction)logout{
    NSLog(@"退出账户");
    [[InCommon sharedInstance] clearUserInfo];
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
    return 5;
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
            cell.textLabel.text = @"Feedback";
            break;
        case 2:
            cell.textLabel.text = @"Buy more innway";
            break;
        case 3:
            cell.textLabel.text = @"Help Center";
            break;
        case 4:{
            cell.textLabel.text = @"Display User Location";
            self.locationBtn.on = YES;
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
