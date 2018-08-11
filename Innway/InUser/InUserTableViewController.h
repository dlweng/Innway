//
//  InUserTableViewController.h
//  Innway
//
//  Created by danly on 2018/8/4.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 界面显示类型
 */
typedef NS_ENUM(NSInteger, InUserViewType) {
    /**
     带有邮箱和密码的界面类型
     */
    InUserWithPassword = 0,
    
    /**
     只带邮箱的类型
     */
    InUserNotPassword = 1
};


@interface InUserTableViewController : UITableViewController

@property (nonatomic, assign) InUserViewType userViewType;
@property (nonatomic, strong) void(^emailValueChanging) (NSString *email);
@property (nonatomic, strong) void(^pwdValueChanging) (NSString *pwd);
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *pwd;

@end
