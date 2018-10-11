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

@end

@implementation InUserSettingViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:InSettingViewCellReuseIdentifier];
    self.tableView.scrollEnabled = NO;
    
    [self addLocationBtn];
    
    self.logoutBtn.layer.masksToBounds = YES;
    self.logoutBtn.layer.cornerRadius = 10;
}

#pragma mark - Action
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
    [[InCommon sharedInstance] clearUserInfo];
    if (self.logoutUser) {
        // 清除云端列表
        [[DLCloudDeviceManager sharedInstance] deleteCloudList];
        self.logoutUser();
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 3;
        case 1:
            return 1;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:InSettingViewCellReuseIdentifier];
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"修改密码";
                break;
            case 1:
                cell.textLabel.text = @"问题反馈";
                break;
            case 2:
                cell.textLabel.text = @"购买设备";
                break;
            default:
                break;
        }
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if(indexPath.section == 1) {
        cell.textLabel.text = @"显示用户位置";
        self.locationBtn.on = YES;
        cell.accessoryView = self.locationBtn;
    }
    return cell;
}

// 下面两个方法都必须设置，才能成功设置分组头的值
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        NSString *email = @"8888888@qq.com";
        return [NSString stringWithFormat:@"   用户: %@", email];
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        UILabel *label = [[UILabel alloc] init];
        NSString *email = [InCommon sharedInstance].email;
        label.text = [NSString stringWithFormat:@"   用户: %@", email];
        label.font = [UIFont systemFontOfSize:16.0];
        label.textColor = [UIColor darkGrayColor];
        return label;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
