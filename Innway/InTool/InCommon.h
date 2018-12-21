//
//  InCommonTool.h
//  Innway
//
//  Created by danly on 2018/8/11.test
//  Copyright © 2018年 innwaytech. All rights reserved.
//

//#ifdef DEBUG
//#define NSLog(format, ...) printf("\n[%s] %s [第%d行] %s\n", __TIME__, __FUNCTION__, __LINE__, [[NSString stringWithFormat:format, ## __VA_ARGS__] UTF8String]);
//#else
//#define NSLog(format, ...)
//#endif


#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import <MBProgressHUD.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define common [InCommon sharedInstance]
#define httpDomain @"http://3.16.195.135/GetData.ashx"
#define ApplicationWillEnterForeground @"ApplicationWillEnterForeground"
#define ApplicationDidEnterBackground @"ApplicationDidEnterBackground"

/**
 界面显示类型
 */
typedef NS_ENUM(NSInteger, InDeviceType) {
    
    /**
     未知设备类型
     */
    InDeviceNone = 0,
    
    /**
     card设备
     */
    InDeviceCard = 1,
    
    /**
     chip设备
     */
    InDeviceChip = 2,
    
    /**
     tag设备
     */
    InDeviceTag = 3,
    
    /**
     所有设备类型
     */
    InDeviceAll = 4,
};

@class DLDevice;
@interface InCommon : NSObject
@property (nonatomic, assign) NSInteger ID; // 用户ID
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *pwd;
//标识是否支持定位功能
@property (nonatomic, assign) BOOL isLocation;
@property (nonatomic, assign) CLLocationCoordinate2D currentLocation;

@property (nonatomic, assign) InDeviceType deviceType; //保存此次查找的设备类型

@property (nonatomic, assign) BOOL isSharkAnimationing;
@property (nonatomic, assign) BOOL unFirstLogin;

+ (instancetype)sharedInstance;

- (void)saveUserInfoWithID:(NSInteger)ID email:(NSString *)email pwd:(NSString *)pwd;
- (void)clearUserInfo;

// 保存地图是否显示用户当前位置
- (void)saveUserLocationIsShow:(BOOL)showUserLocation;
- (BOOL)getIsShowUserLocation;

// 进入到系统的APP设置界面
- (void)goToAPPSetupView;

// 保存云端列表
- (void)saveCloudList:(NSArray *)cloudList;
- (void)saveCloudListWithDevice:(DLDevice *)device;
- (void)removeDeviceByCloudList:(DLDevice *)device;
// 获取本地保存的云端列表，只在每次进入APP时无网络时调用
// 在每次获取云端列表。增加删除设备时更新；最新离线，gps，设备信息另外保存
- (NSArray *)getCloudList;

// 设置闪光灯 打开的时候关闭，关闭的时候打开
- (void)setupSharkLight;

- (void)startSharkAnimation;
- (void)stopSharkAnimation;

// 返回false，说明当前APP没有开启定位功能
- (NSString *)getCurrentGps;
- (BOOL)startUpdatingLocation;
- (void)uploadDeviceLocation:(DLDevice *)device;
- (BOOL)isOpensLocation;

// 获取RSSI对应的图片名称
- (NSString *)getImageName:(NSNumber *)rssi;

// 根据外设获取设备类型
- (InDeviceType)getDeviceType:(CBPeripheral *)peripheral;

// 发送本地通知
+ (void)sendLocalNotification:(NSString *)message;
+ (BOOL)isOpenNotification;

// 网络请求接口
+ (void)sendHttpMethod:(NSString *)method URLString:(NSString *)URLString body:(NSDictionary *)body completionHandler:(nullable void (^)(NSURLResponse *response, NSDictionary *responseObject,  NSError * _Nullable error))completionHandler;

+ (BOOL)isIPhoneX; // 返回是否是刘海屏
// 设置导航栏图片
+ (void)setNavgationBar:(UINavigationBar *)bar;

#pragma mark - date
//获取当前的时间 1980-01-01 00:00:01
- (NSString *)getCurrentTime;
// 字符串转换为日期  字符串格式：1980-01-01 00:00:01
- (NSDate *)dateFromStr:(NSString *)str;
// 字符串转换为日期
- (NSString *)dateStrFromDate:(NSDate *)date;
//  入参是NSDate类型
- (int)compareOneDate:(NSDate *)oneDate withAnotherDate:(NSDate *)anotherDate;
//  入参是NSString类型  oneDateStr距离现在比anotherDateStr距离现在近，返回-1
- (int)compareOneDateStr:(NSString *)oneDateStr withAnotherDateStr:(NSString *)anotherDateStr;
- (NSDateComponents *)differentWithDate:(NSString *)expireDateStr;

// 离线信息保存
- (void)saveDeviceOfflineInfo:(DLDevice *)device;
- (void)getDeviceOfflineInfo:(DLDevice *)device completion:(void (^)(NSString * offlineTime, NSString * gps))completion;
// 保存设备名称
- (void)saveDeviceName:(DLDevice *)device;
- (void)getDeviceName:(DLDevice *)device;
// 从16进制字符串获取到10进制数值
- (NSInteger)getIntValueByHex:(NSString *)getStr;
//后台任务
- (BOOL)beginBackgroundTask;
- (void)endBackgrondTask;

// iBeacon
- (void)startiBeaconListen;
- (void)stopIbeaconListen;
- (void)stopiBeaconBackgroundTask;
@end

@interface NSDictionary (GetValue)

- (NSString *)stringValueForKey:(NSString *)key defaultValue:(NSString *)defaultValue;
- (NSNumber *)numberValueForKey:(NSString *)key defaultValue:(NSNumber *)defaultValue;
- (NSInteger)integerValueForKey:(NSString *)key defaultValue:(NSInteger)defaultValue;
- (BOOL)boolValueForKey:(NSString *)key defaultValue:(BOOL)defaultValue;
- (double)doubleValueForKey:(NSString *)key defaultValue:(double)defaultValue;
- (NSArray *)arrayValueForKey:(NSString *)key defaultValue:(NSArray *)defaultValue;
- (NSDictionary *)dictValueForKey:(NSString *)key defaultValue:(NSDictionary *)defaultValue;

@end

// 显示加载圈
@interface InAlertTool : NSObject
+ (void)showHUDAddedTo:(UIView *)view animated:(BOOL)animated;
+ (void)showHUDAddedTo:(UIView *)view tips:(NSString *)tips tag:(NSInteger)tag animated:(BOOL)animated;
+ (void)hideHUDForView:(UIView *)view tag:(NSInteger)tag;
@end

// 显示交互提示框
typedef void (^confirmHanler)(void);
@interface InAlertView : UIView
+ (InAlertView *)showAlertWithTitle:(NSString *)title message:(NSString *)message confirmHanler:(confirmHanler)confirmHanler;
+ (InAlertView *)showAlertWithMessage:(NSString *)message confirmHanler:(confirmHanler)confirmHanler cancleHanler:(confirmHanler)cancleHanler;
@end
