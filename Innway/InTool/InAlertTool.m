//
//  InAlertTool.m
//  Innway
//
//  Created by danly on 2018/8/11.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InAlertTool.h"
#import <objc/runtime.h>

@implementation UIAlertController (InAlertTool)

@dynamic alertWindow;

- (void)setAlertWindow:(UIWindow *)alertWindow {
    objc_setAssociatedObject(self, @selector(alertWindow), alertWindow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIWindow *)alertWindow {
    return objc_getAssociatedObject(self, @selector(alertWindow));
}

- (void)show {
    self.alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.alertWindow.rootViewController = [[UIViewController alloc] init];
    self.alertWindow.windowLevel = [UIApplication sharedApplication].windows.lastObject.windowLevel+1;
    [self.alertWindow makeKeyAndVisible];
    [self.alertWindow.rootViewController presentViewController:self animated:YES completion:nil];
}

- (void)viewDidDisappear:(BOOL)animated { //弹框消失的事件处理
    [super viewDidDisappear:animated];
    self.alertWindow.hidden = YES;
    self.alertWindow = nil;
}

- (void)allLabels:(UIView *)view labels:(NSMutableArray *)labels { //获取弹框中所有的标签，用于修改对齐方式，或者其他
    for (UILabel *label in view.subviews) {
        if ([label isKindOfClass:[UILabel class]]) {
            [labels addObject:label];
        }
        [self allLabels:label labels:labels];
    }
}

- (UILabel *)detailTextLabel { //获取详细信息的标签
    NSMutableArray *labels = [NSMutableArray array];
    [self allLabels:self.view labels:labels];
    if (labels.count == 2) {
        return labels[1];
    }
    return nil;
}

@end

@implementation InAlertTool

+ (UIAlertController *)showAlertWithTip:(NSString *)message { //默认title为tip的情况
    NSString *title = @"提示";
    NSString *confirm = @"确定";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:confirm style:UIAlertActionStyleCancel handler:nil]];
    [alertController show];
    return alertController;
}

+ (UIAlertController *)showAlert:(NSString *)title message:(NSString *)message {
    NSString *confirm = @"确定";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:confirm style:UIAlertActionStyleCancel handler:nil]];
    [alertController show];
    return alertController;
}

+ (UIAlertController *)showAlert:(NSString *)title message:(NSString *)message confirmHanler:(void (^)(void))confirmHanler{
    NSString *confirm = @"确定";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:confirm style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (confirmHanler) {
            confirmHanler();
        }
    }]];
    [alertController show];
    return alertController;
}

+ (void)showAlertAutoDisappear:(NSString *)message { //默认2.0s后自动隐藏弹框
    [self showAlertAutoDisappear:message completion:nil];
}

+ (void)showAlertAutoDisappear:(NSString *)message completion:(void (^)(void))completion { //自动隐藏弹框后可选有完成事件
    __block UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController show];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [alertController dismissViewControllerAnimated:YES completion:completion];
        alertController = nil;
    });
}

+ (void)showHUDAddedTo:(UIView *)view animated:(BOOL)animated {
    if (view) {
        MBProgressHUD *hud = [MBProgressHUD HUDForView:view];
        if (!animated || hud.alpha == 0) {
            [MBProgressHUD showHUDAddedTo:view animated:animated];
        }
    }
}

+ (void)showHUDAddedTo:(UIView *)view tips:(NSString *)tips tag:(NSInteger)tag animated:(BOOL)animated {
    if (![self findHUDForView:view tag:tag]) {
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:view];
        hud.tag = tag;
        hud.label.text = tips;
        hud.label.adjustsFontSizeToFitWidth = YES;
        hud.label.minimumScaleFactor = 0.3;
        hud.removeFromSuperViewOnHide = YES;
        [view addSubview:hud];
        [hud showAnimated:YES];
    }
}

+ (void)hideHUDForView:(UIView *)view tag:(NSInteger)tag {
    MBProgressHUD *hud = [self findHUDForView:view tag:tag];
    if (hud != nil) {
        hud.removeFromSuperViewOnHide = YES;
        [hud hideAnimated:YES];
    }
}

+ (MBProgressHUD *)findHUDForView:(UIView *)view tag:(NSInteger)tag {
    NSEnumerator *subviewsEnum = [view.subviews reverseObjectEnumerator];
    for (UIView *subview in subviewsEnum) {
        if ([subview isKindOfClass:[MBProgressHUD class]] && subview.tag == tag) {
            return (MBProgressHUD *)subview;
        }
    }
    return nil;
}

@end
