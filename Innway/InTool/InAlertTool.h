//
//  InAlertTool.h
//  Innway
//
//  Created by danly on 2018/8/11.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIAlertController (InAlertTool)
@property (strong, nonatomic) UIWindow *alertWindow;
@property (strong, nonatomic, readonly) UILabel *detailTextLabel;
- (void)show;
@end

@interface InAlertTool : NSObject

+ (UIAlertController *)showAlertWithTip:(NSString *)message;
+ (UIAlertController *)showAlert:(NSString *)title message:(NSString *)message;
+ (void)showAlertAutoDisappear:(NSString *)message;
+ (void)showAlertAutoDisappear:(NSString *)message completion:(void (^)(void))completion;

@end
