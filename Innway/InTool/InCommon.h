//
//  InCommonTool.h
//  Innway
//
//  Created by danly on 2018/8/11.
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
@property (nonatomic, assign) NSInteger ID;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *pwd;
//标识是否支持定位功能
@property (nonatomic, assign) BOOL isLocation;
@property (nonatomic, assign) CLLocationCoordinate2D currentLocation;
@property (nonatomic, assign) InDeviceType deviceType;
+ (instancetype)sharedInstance;

- (void)saveUserInfoWithID:(NSInteger)ID email:(NSString *)email pwd:(NSString *)pwd;
- (void)saveUserLocationIsShow:(BOOL)showUserLocation;
- (BOOL)getIsShowUserLocation;
- (void)goToAPPSetupView;
- (void)clearUserInfo;
- (void)saveCloudList:(NSArray *)cloudList;
- (void)saveCloudListWithDevice:(DLDevice *)device;
- (void)removeDeviceByCloudList:(DLDevice *)device;
- (NSArray *)getCloudList;

//音频
- (void)playSoundAlertMusic;
- (void)stopSoundAlertMusic;
- (void)playSound;
- (void)stopSound;

// 设置闪光灯 打开的时候关闭，关闭的时候打开
- (void)setupSharkLight;

// 返回false，说明当前APP没有开启定位功能
- (NSString *)getCurrentGps;
- (BOOL)startUpdatingLocation;
- (void)uploadDeviceLocation:(DLDevice *)device;
- (BOOL)isOpensLocation;

- (NSString *)getImageName:(NSNumber *)rssi;
// 根据外设获取设备类型
- (InDeviceType)getDeviceType:(CBPeripheral *)peripheral;
// 发送本地通知
- (void)sendLocalNotification:(NSString *)message;

+ (void)sendHttpMethod:(NSString *)method URLString:(NSString *)URLString body:(NSDictionary *)body completionHandler:(nullable void (^)(NSURLResponse *response, NSDictionary *responseObject,  NSError * _Nullable error))completionHandler;

+ (BOOL)isIPhoneX;
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
//  入参是NSString类型
- (int)compareOneDateStr:(NSString *)oneDateStr withAnotherDateStr:(NSString *)anotherDateStr;
- (NSDateComponents *)differentWithDate:(NSString *)expireDateStr;
- (void)saveDeviceOfflineInfo:(DLDevice *)device;
- (void)getDeviceOfflineInfo:(DLDevice *)device completion:(void (^)(NSString * offlineTime, NSString * gps))completion;
- (void)saveDeviceName:(DLDevice *)device;
- (void)getDeviceName:(DLDevice *)device;
- (NSInteger)getIntValueByHex:(NSString *)getStr;
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

typedef void (^confirmHanler)(void);
@interface InAlertView : UIView
+ (InAlertView *)showAlertWithTitle:(NSString *)title message:(NSString *)message confirmHanler:(confirmHanler)confirmHanler;
+ (InAlertView *)showAlertWithMessage:(NSString *)message confirmHanler:(confirmHanler)confirmHanler cancleHanler:(confirmHanler)cancleHanler;
@end
