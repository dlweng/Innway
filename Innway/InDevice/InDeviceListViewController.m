//
//  InDeviceMenuViewController.m
//  Innway
//
//  Created by danly on 2018/8/5.
//  Copyright © 2018年 innwaytech. All rights reserved.
//
#define InDeviceListCellReuseIdentifier @"InDeviceListCell"
#define InDeviceListAddDeviceCellReuseIdentifier @"InDeviceListAddDeviceCell"

#import "InDeviceListViewController.h"
#import "DLCloudDeviceManager.h"
#import "InDeviceListCell.h"
#import "InDeviceListAddDeviceCell.h"
#import "InCommon.h"

@interface InDeviceListViewController ()<UITableViewDelegate, UITableViewDataSource, InDeviceListCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *cloudList;
@property (weak, nonatomic) IBOutlet UIView *upDownView;
@property (nonatomic, assign) CGPoint oldPoint;
@property (weak, nonatomic) IBOutlet UIImageView *upDownImage;

@end

@implementation InDeviceListViewController

+ (instancetype)DeviceListViewControllerWithCloudList:(NSArray *)cloudList {
    InDeviceListViewController *menuVC = [[InDeviceListViewController alloc] init];
    menuVC.tableView.backgroundColor = [UIColor redColor];
    menuVC.cloudList = cloudList;
    return menuVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"InDeviceListCell" bundle:nil] forCellReuseIdentifier:InDeviceListCellReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"InDeviceListAddDeviceCell" bundle:nil] forCellReuseIdentifier:InDeviceListAddDeviceCellReuseIdentifier];
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
        InDeviceListAddDeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:InDeviceListAddDeviceCellReuseIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        return cell;
    }
    else {
        InDeviceListCell *cell = [tableView dequeueReusableCellWithIdentifier:InDeviceListCellReuseIdentifier];
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
        if ([self.delegate respondsToSelector:@selector(deviceListViewControllerDidSelectedToAddDevice:)]) {
            [self.delegate deviceListViewControllerDidSelectedToAddDevice:self];
        }
    }
    else {
        DLDevice *device = self.cloudList[indexPath.row];
        if ([self.delegate respondsToSelector:@selector(deviceListViewController:didSelectedDevice:)]) {
            [self.delegate deviceListViewController:self didSelectedDevice:device];
        }
    }
}

- (void)deviceOnlineChange:(NSNotification *)noti {
    [self.tableView reloadData];
}

- (void)deviceListCellSettingBtnDidClick:(InDeviceListCell *)cell {
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
            [self.delegate deviceListViewController:self moveDown:point.y];
        }
    }
    else {
        if (point.y < 0) {
            [self.delegate deviceListViewController:self moveDown:point.y];
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
