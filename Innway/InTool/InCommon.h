//
//  InCommonTool.h
//  Innway
//
//  Created by danly on 2018/8/11.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import <MBProgressHUD.h>

#define common [InCommon sharedInstance]

/**
 界面显示类型
 */
typedef NS_ENUM(NSInteger, InSearchDeviceType) {
    InDeviceTag = 0,
    InDeviceChip = 1,
    InDeviceCard = 2
};

@class DLDevice;
@interface InCommon : NSObject
@property (nonatomic, assign) NSInteger ID;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *pwd;
//标识是否支持定位功能
@property (nonatomic, assign) BOOL isLocation;
@property (nonatomic, assign) CLLocationCoordinate2D currentLocation;
@property (nonatomic, assign) InSearchDeviceType searchDeviceType;
+ (instancetype)sharedInstance;

- (void)saveUserInfoWithID:(NSInteger)ID email:(NSString *)email pwd:(NSString *)pwd;
- (void)clearUserInfo;

- (void)saveCloudList:(NSArray *)cloudList;
- (void)saveCloudListWithDevice:(DLDevice *)device;
- (void)removeDeviceByCloudList:(DLDevice *)device;
- (NSArray *)getCloudList;


- (void)playSound;
- (void)stopSound;

// 返回false，说明当前APP没有开启定位功能
- (NSString *)getCurrentGps;
- (BOOL)startUpdatingLocation;
- (void)uploadDeviceLocation:(DLDevice *)device;

- (NSString *)getImageName:(NSNumber *)rssi;

+ (void)sendHttpMethod:(NSString *)method URLString:(NSString *)URLString body:(NSDictionary *)body completionHandler:(nullable void (^)(NSURLResponse *response, NSDictionary *responseObject,  NSError * _Nullable error))completionHandler;

+ (BOOL)isIPhoneX;

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
