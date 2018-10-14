//
//  InDeviceMenuViewController.m
//  Innway
//
//  Created by danly on 2018/8/5.
//  Copyright © 2018年 innwaytech. All rights reserved.
//
#define InDeviceMenuCell1ReuseIdentifier @"InDeviceMenuCell1"
#define InDeviceMenuCell2ReuseIdentifier @"InDeviceMenuCell2"

#import "InDeviceMenuViewController.h"
#import "DLCloudDeviceManager.h"
#import "InDeviceListViewController.h"
#import "InDeviceMenuCell1.h"
#import "InDeviceMenuCell2.h"
#import "InCommon.h"

@interface InDeviceMenuViewController ()<UITableViewDelegate, UITableViewDataSource, InDeviceMenuCell1Delegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *cloudList;
@property (weak, nonatomic) IBOutlet UIView *upDownView;
@property (nonatomic, assign) CGPoint oldPoint;
@property (weak, nonatomic) IBOutlet UIImageView *upDownImage;

@end

@implementation InDeviceMenuViewController

+ (instancetype)menuViewControllerWithCloudList:(NSArray *)cloudList {
    InDeviceMenuViewController *menuVC = [[InDeviceMenuViewController alloc] init];
    menuVC.tableView.backgroundColor = [UIColor redColor];
    menuVC.cloudList = cloudList;
    return menuVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"InDeviceMenuCell1" bundle:nil] forCellReuseIdentifier:InDeviceMenuCell1ReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"InDeviceMenuCell2" bundle:nil] forCellReuseIdentifier:InDeviceMenuCell2ReuseIdentifier];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOnlineChange:) name:DeviceOnlineChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceRSSIChange:) name:DeviceRSSIChangeNotification object:nil];
    self.view.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.upDownView.userInteractionEnabled = YES;
    [self.upDownView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(upDown:)]];
    self.down = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceOnlineChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceRSSIChangeNotification object:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cloudList.count + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.cloudList.count) {
        return 50;
    }
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.cloudList.count) {
        InDeviceMenuCell2 *cell = [tableView dequeueReusableCellWithIdentifier:InDeviceMenuCell2ReuseIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        return cell;
    }
    else {
        InDeviceMenuCell1 *cell = [tableView dequeueReusableCellWithIdentifier:InDeviceMenuCell1ReuseIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        DLDevice *device = self.cloudList[indexPath.row];
        cell.device = device;
        cell.delegate = self;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row == self.cloudList.count) {
        if ([self.delegate respondsToSelector:@selector(menuViewControllerDidSelectedToAddDevice:)]) {
            [self.delegate menuViewControllerDidSelectedToAddDevice:self];
        }
    }
    else {
        DLDevice *device = self.cloudList[indexPath.row];
        if ([self.delegate respondsToSelector:@selector(menuViewController:didSelectedDevice:)]) {
            [self.delegate menuViewController:self didSelectedDevice:device];
        }
    }
}

- (void)deviceOnlineChange:(NSNotification *)noti {
    [self.tableView reloadData];
}

- (void)deviceMenuCellSettingBtnDidClick:(InDeviceMenuCell1 *)cell {
    if ([self.delegate respondsToSelector:@selector(deviceSettingBtnDidClick:)]) {
        [self.delegate deviceSettingBtnDidClick:cell.device];
    }
}

- (void)deviceRSSIChange:(NSNotification *)noti {
    [self.tableView reloadData];
}

- (void)reloadView:(NSArray *)cloudList {
    if (cloudList) {
        self.cloudList = cloudList;
    }
    [self.tableView reloadData];
}

- (void)upDown:(UIPanGestureRecognizer *)pan {
//    NSLog(@"pan = %@", [NSValue valueWithCGPoint:[pan locationInView:self.view]]);
    CGPoint point = [pan locationInView:self.view];
    if (self.down) {
        if (point.y > 0) {
            [self.delegate menuViewController:self moveDown:point.y];
        }
    }
    else {
        if (point.y < 0) {
            [self.delegate menuViewController:self moveDown:point.y];
        }
    }
}

- (void)setDown:(BOOL)down {
    _down = down;
    if (down) {
        self.upDownImage.image = [UIImage imageNamed:@"down"];
    }
    else {
        self.upDownImage.image = [UIImage imageNamed:@"up"];
    }
}


@end
