//
//  InHelpCenterSelectionController.m
//  Innway
//
//  Created by danly on 2018/10/27.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InHelpCenterSelectionController.h"
#import "InCommon.h"
#import "InHelpCenterInfoController.h"
#import "NSTimer+InTimer.h"

@interface InHelpCenterSelectionController ()<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;

@end

@implementation InHelpCenterSelectionController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNarBar];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    self.tableView.scrollEnabled = NO;
}

- (void)setupNarBar {
    self.navigationController.navigationBar.hidden = NO;
    self.navigationItem.title = @"Help Center";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    if ([UIDevice currentDevice].systemVersion.integerValue < 11) {
        self.tableViewHeightConstraint.constant = 280;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    InDeviceType deviceType = InDeviceNone;
    switch (indexPath.row) {
        case 0:
            deviceType = InDeviceCard;
            break;
//        case 1:
//            deviceType = InDeviceTag;
//            break;
        case 1:
            deviceType = InDeviceChip;
            break;
        default:
            break;
    }
    InHelpCenterInfoController *helpCenterInfoVC = [[InHelpCenterInfoController alloc] initWithType:deviceType];
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController pushViewController:helpCenterInfoVC animated:YES];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.textColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1];
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Innway Card Instructions";
            break;
//        case 1:
//            cell.textLabel.text = @"Innway Tag Instructions";
//            break;
        case 1:
            cell.textLabel.text = @"Innway Chip Instructions";
            break;
        default:
            break;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55;
}

- (void)goBack {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)dealloc {
    
}

@end
