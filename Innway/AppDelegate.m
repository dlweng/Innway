//
//  AppDelegate.m
//  Innway
//
//  Created by danly on 2018/8/1.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "AppDelegate.h"
#import "DLCentralManager.h"
#import "DLCloudDeviceManager.h"
#import "InCommon.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // 设置导航栏
    UINavigationBar *navigationBar = [UINavigationBar appearance];
    navigationBar.tintColor = [UIColor whiteColor];
    // 启动蓝牙功能
    __block NSNumber *isShowAlterView = @NO;
    __block InAlertView *alertView;
    [DLCentralManager startSDKCompletion:^(DLCentralManager *manager, CBCentralManagerState state) {
        if (state != CBCentralManagerStatePoweredOn) {
            if (!isShowAlterView.boolValue) {
                isShowAlterView = @YES;
                alertView = [InAlertView showAlertWithTitle:@"Information" message:@"Enable Bluetooth to pair with the device." confirmTitle:nil confirmHanler:^{
                    isShowAlterView = @NO;
                }];
            }
        }
        else {
            if (alertView) {
                // 移除并重置状态
                [alertView removeFromSuperview];
                alertView = nil;
                isShowAlterView = @NO;
            }
        }
    }];
    
    // 设置状态栏
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    // 设置通知
    UIUserNotificationType type = UIUserNotificationTypeAlert | UIUserNotificationTypeSound;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:type categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[NSNotificationCenter defaultCenter] postNotificationName:APPBeKilledNotification object:nil];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[NSNotificationCenter defaultCenter] postNotificationName:ApplicationDidEnterBackground object:nil];
//    NSLog(@"进入后台，监听iBeacon");
//    [common startiBeaconListen];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
//    NSLog(@"进入前台，关闭iBeacon监听");
//    [common stopIbeaconListen];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
     [[NSNotificationCenter defaultCenter] postNotificationName:ApplicationWillEnterForeground object:nil];
    // 清楚所有的通知
    [UIApplication sharedApplication].applicationIconBadgeNumber = 1;
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    
}

@end
