//
//  InCommonTool.m
//  Innway
//
//  Created by danly on 2018/8/11.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InCommon.h"
#import "DLDevice.h"
#import <AFNetworking.h>

static SystemSoundID soundID;
@interface InCommon ()<CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation InCommon

+ (instancetype)sharedInstance {
    static InCommon *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[InCommon alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self getUserInfo];
        soundID = 1;
        [self.locationManager requestAlwaysAuthorization];
    }
    return self;
}

- (void)saveUserInfoWithID:(NSNumber *)ID email:(NSString *)email pwd:(NSString *)pwd {
    self.ID = ID.integerValue;
    self.email = email;
    self.pwd = pwd;
    if (self.ID && self.email && self.pwd) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:ID forKey:@"ID"];
        [defaults setValue:email forKey:@"email"];
        [defaults setValue:pwd forKey:@"pwd"];
        [defaults synchronize];
    }
}

- (void)getUserInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *IDNumber = [defaults valueForKey:@"ID"];
    if (IDNumber) {
        self.ID = IDNumber.integerValue;
        self.email = [defaults valueForKey:@"email"];
        self.pwd = [defaults valueForKey:@"pwd"];
    }
    else {
        self.ID = -1;
        self.email = nil;
        self.pwd = nil;
    }
}

- (void)clearUserInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"ID"];
    [defaults removeObjectForKey:@"email"];
    [defaults removeObjectForKey:@"pwd"];
    [defaults synchronize];
    self.ID = -1;
    self.email = nil;
    self.pwd = nil;
}

- (void)uploadDeviceLocation:(DLDevice *)device {
    NSString *gps = [device getGps];
    if (gps.length == 0) {
        return;
    }
    NSLog(@"开始上传设备%@的位置", device.mac);
    NSDictionary *parameters = @{@"deviceid":device.cloudID, @"gps":gps};
    [[AFHTTPSessionManager manager] POST:@"http://111.230.192.125/device/updateDeviceGPS" parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSLog(@"上传设备位置结果: %@", responseObject);
            NSNumber *code = responseObject[@"code"];
            NSString *message = responseObject[@"message"];
            if (code.integerValue == 200) {
            }
            else if (code.integerValue == 500) {
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"上传位置失败, %@", error);
    }];
}

#pragma mark - 手机报警
- (void)playSound {
    AudioServicesDisposeSystemSoundID(soundID);
    NSNumber *phoneAlertMusic = [[NSUserDefaults standardUserDefaults] objectForKey:PhoneAlertMusicKey];
    NSString *alertMusic;
    switch (phoneAlertMusic.integerValue) {
        case 2:
            alertMusic = @"voice2.mp3";
            break;
        case 3:
            alertMusic = @"voice3.mp3";
            break;
        default:
            alertMusic = @"voice1.mp3";
            break;
    }
    //    创建一个系统声音的服务
    AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)([[NSBundle mainBundle]URLForResource:alertMusic withExtension:nil]), &soundID);
    //    播放系统声音
    AudioServicesPlayAlertSound(soundID);
}

- (void)stopSound {
    AudioServicesDisposeSystemSoundID(soundID);
}

#pragma mark - 定位
/**
 *  当授权状态发生改变了就会调用该代理方法
 *
 *  @param manager 位置管理器
 *  @param status  授权状态
 */
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    //  判断是否授权成功
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        NSLog(@"授权在前台后台都可进行定位");
        [self setupLocationData];
    } else if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        NSLog(@"授权只允许在使用期间定位");
        [self setupLocationData];
    }
    else{
        NSLog(@"用户拒绝授权");
        self.isLocation = NO;
    }
}

/**
 *  当用户位置更新了就会调用该代理方法
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation *location =  [locations firstObject];
    //  获取当前位置的经纬度
    self.currentLocation = location.coordinate;
    NSLog(@"common 地图位置更新: %f, %f", location.coordinate.latitude, location.coordinate.longitude);
    //  输出经纬度信息
    //  纬度:23.130250,经度:113.383898
    //  北纬正数,南纬:负数  东经:正数  西经:负数
    NSLog(@"纬度:%lf,经度:%lf",self.currentLocation.latitude,self.currentLocation.longitude);
    
}

- (void)setupLocationData {
    self.isLocation = YES;
    // 设置定位精度,越精确越费电
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    // 设置用户的位置改变多少m才去调用位置更新的方法
    self.locationManager.distanceFilter =  100;
    [self.locationManager startUpdatingLocation];
}

- (BOOL)startUpdatingLocation {
    if (self.locationManager) {
        [self.locationManager startUpdatingLocation];
        return YES;
    }
    return NO;
}

- (CLLocationManager *)locationManager
{
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (NSString *)getImageName:(NSNumber *)rssi {
    NSInteger rSSI = rssi.integerValue;
    NSString *imageName = @"RSSI_11";
    if(rSSI>=-50)
    {
        imageName = @"RSSI_0";
    }
    else if(rSSI>-60)//>90%
    {
        imageName = @"RSSI_1";
    }
    else if(rSSI>-65)//>80%
    {
        imageName = @"RSSI_2";
    }
    else if(rSSI>-70)//>70%
    {
        imageName = @"RSSI_3";
    }
    else if(rSSI>-75)//>60%
    {
        imageName = @"RSSI_4";
    }
    else if(rSSI>-80)//>50%
    {
        imageName = @"RSSI_5";
    }
    else if(rSSI>-85)//>40%
    {
        imageName = @"RSSI_6";
    }
    else if(rSSI>-90)//>30%
    {
        imageName = @"RSSI_7";
    }
    else if(rSSI>-95)//>20%
    {
        imageName = @"RSSI_8";
    }
    else if(rSSI>-100)//>10%
    {
        imageName = @"RSSI_9";
    }
    else{
        imageName = @"RSSI_11";
    }
    return imageName;
}

@end
