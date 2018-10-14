//
//  InDeviceMenuViewController.h
//  Innway
//
//  Created by danly on 2018/8/5.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import <UIKit/UIKit.h>

@class InDeviceListViewController;
@class DLDevice;
@protocol InDeviceListViewControllerDelegate<NSObject>
- (void)deviceListViewController:(InDeviceListViewController *)menuVC didSelectedDevice:(DLDevice *)device;
- (void)deviceListViewControllerDidSelectedToAddDevice:(InDeviceListViewController *)menuVC;
- (void)deviceListViewController:(InDeviceListViewController *)menuVC moveDown:(CGFloat)down;
- (void)deviceSettingBtnDidClick:(DLDevice *)device;
@end

@interface InDeviceListViewController : UIViewController

+ (instancetype)DeviceListViewControllerWithCloudList:(NSArray *)cloudList;
- (void)reloadView:(NSArray *)cloudList;

@property (nonatomic, weak) id<InDeviceListViewControllerDelegate> delegate;
// YES: 标识能向下移动， NO:表示能向上移动
@property (nonatomic, assign) BOOL down;

@end
