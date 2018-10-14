//
//  InUserSettingViewController.h
//  Innway
//
//  Created by danly on 2018/8/5.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import <UIKit/UIKit.h>

@class InUserSettingViewController;
@protocol InUserSettingViewControllerDelegate<NSObject>
- (void)settingViewController:(InUserSettingViewController *)settingVC touchMove:(CGPoint)move;
- (void)settingViewController:(InUserSettingViewController *)settingVC touchEnd:(CGPoint)move;
- (void)settingViewController:(InUserSettingViewController *)settingVC didSelectRow:(NSInteger)row;
- (void)settingViewController:(InUserSettingViewController *)settingVC showUserLocation:(BOOL)showUserLocation;
@end

@interface InUserSettingViewController : UIViewController
@property (nonatomic, strong) void(^logoutUser) (void);
@property (nonatomic, weak) id<InUserSettingViewControllerDelegate> delegate;
//+ (instancetype)UserSettingViewController;
@end
