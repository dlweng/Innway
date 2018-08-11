//
//  InUserSettingViewController.h
//  Innway
//
//  Created by danly on 2018/8/5.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InUserSettingViewController : UIViewController

@property (nonatomic, strong) void(^leftGestureCompleted) (UIGestureRecognizer *gesture);
@property (nonatomic, strong) void(^logoutUser) (void);

@end
