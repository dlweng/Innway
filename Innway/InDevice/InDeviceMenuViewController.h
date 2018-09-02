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
- (void)deviceSettingBtnDidClick:(DLDevice *)device;
@end

@interface InDeviceMenuViewController : UIViewController

+ (instancetype)menuViewController;
@property (nonatomic, weak) id<InDeviceMenuViewControllerDelegate> delegate;

@end
