//
//  InCommonTool.h
//  Innway
//
//  Created by danly on 2018/8/11.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSDictionary+GetValue.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CoreLocation/CoreLocation.h>

@class DLDevice;
@interface InCommon : NSObject
@property (nonatomic, assign) NSInteger ID;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *pwd;
//标识是否支持定位功能
@property (nonatomic, assign) BOOL isLocation;
@property (nonatomic, assign) CLLocationCoordinate2D currentLocation;
+ (instancetype)sharedInstance;

- (void)saveUserInfoWithID:(NSNumber *)ID email:(NSString *)email pwd:(NSString *)pwd;
- (void)clearUserInfo;

- (void)playSound;
- (void)stopSound;

// 返回false，说明当前APP没有开启定位功能
- (BOOL)startUpdatingLocation;
- (void)uploadDeviceLocation:(DLDevice *)device;

@end
