//
//  InDeviceMenuViewController.h
//  Innway
//
//  Created by danly on 2018/8/5.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import <UIKit/UIKit.h>

@class InDeviceMenuViewController;
@class DLDevice;
@protocol InDeviceMenuViewControllerDelegate<NSObject>
- (void)menuViewController:(InDeviceMenuViewController *)menuVC didSelectedDevice:(DLDevice *)device;
- (void)menuViewControllerDidSelectedToAddDevice:(InDeviceMenuViewController *)menuVC;
- (void)menuViewController:(InDeviceMenuViewController *)menuVC moveDown:(CGFloat)down;
- (void)deviceSettingBtnDidClick:(DLDevice *)device;
@end

@interface InDeviceMenuViewController : UIViewController

+ (instancetype)menuViewControllerWithCloudList:(NSArray *)cloudList;
- (void)reloadView:(NSArray *)cloudList;

@property (nonatomic, weak) id<InDeviceMenuViewControllerDelegate> delegate;
// YES: 标识能向下移动， NO:表示能向上移动
@property (nonatomic, assign) BOOL down;

@end
