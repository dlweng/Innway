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
    UINavigationBar *navigationBar = [UINavigationBar appearance];
    navigationBar.tintColor = [UIColor whiteColor];
    [DLCentralManager startSDKCompletion:^(DLCentralManager *manager, CBCentralManagerState state) {
        if (state == CBCentralManagerStatePoweredOff) {
            [InAlertView showAlertWithTitle:@"Information" message:@"请打开蓝牙" confirmHanler:nil];
        }
        else if (state == CBCentralManagerStatePoweredOn) {
            [manager startScanDeviceWithTimeout:10 discoverEvent:^(DLCentralManager *manager, CBPeripheral *peripheral, NSString *mac) {
                
            } didEndDiscoverDeviceEvent:^(DLCentralManager *manager, NSMutableDictionary<NSString *,DLKnowDevice *> *knownPeripherals) {
                
            }];
        }
    }];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
