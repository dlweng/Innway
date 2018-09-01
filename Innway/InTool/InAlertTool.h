//
//  InAlertTool.h
//  Innway
//
//  Created by danly on 2018/8/11.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MBProgressHUD.h>

@interface UIAlertController (InAlertTool)
@property (strong, nonatomic) UIWindow *alertWindow;
@property (strong, nonatomic, readonly) UILabel *detailTextLabel;
- (void)show;
@end

@interface InAlertTool : NSObject

+ (UIAlertController *)showAlertWithTip:(NSString *)message;
+ (UIAlertController *)showAlert:(NSString *)title message:(NSString *)message;
+ (UIAlertController *)showAlert:(NSString *)title message:(NSString *)message confirmHanler:(void (^)(void))confirmHanler;
+ (void)showAlertAutoDisappear:(NSString *)message;
+ (void)showAlertAutoDisappear:(NSString *)message completion:(void (^)(void))completion;

+ (void)showHUDAddedTo:(UIView *)view animated:(BOOL)animated;
+ (void)showHUDAddedTo:(UIView *)view tips:(NSString *)tips tag:(NSInteger)tag animated:(BOOL)animated;
+ (void)hideHUDForView:(UIView *)view tag:(NSInteger)tag;

@end
