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
#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>

static SystemSoundID soundID; // 离线提示音
@interface InCommon ()<CLLocationManagerDelegate, AVAudioPlayerDelegate, AVAudioPlayerDelegate> {
    NSTimer *_sharkTimer; // 闪光灯计时器
}
@property (nonatomic, strong) CLLocationManager *locationManager;
// 音频播放
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
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
        soundID = -1;
        if ([CLLocationManager locationServicesEnabled]) {
            _locationManager = [[CLLocationManager alloc] init];
            _locationManager.delegate = self;
            [_locationManager requestAlwaysAuthorization];
            [_locationManager startUpdatingLocation];//开始定位
        }
        
        // 设置闪光灯定时器
        _sharkTimer = [NSTimer timerWithTimeInterval:0.4 target:self selector:@selector(setupSharkLight) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_sharkTimer forMode:NSRunLoopCommonModes];
        [self stopSharkAnimation];
    }
    return self;
}

- (void)dealloc {
    [_sharkTimer invalidate];
    _sharkTimer = nil;
}

#pragma mark - 用户信息的存取
- (void)saveUserInfoWithID:(NSInteger)ID email:(NSString *)email pwd:(NSString *)pwd {
    self.ID = ID;
    self.email = email;
    self.pwd = pwd;
    if (self.ID && self.email && self.pwd) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:@(ID) forKey:@"ID"];
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

#pragma mark - 云端列表存取
- (void)saveCloudList:(NSArray *)cloudList {
    if (cloudList == nil || self.ID <= 0) {
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // 云端列表在本地的存储格式
    // @{@"usersCloudListDic": @{@"用户ID": @{用户所属云端设备列表}}}
    NSDictionary *usersCloudListDic = [defaults objectForKey:@"usersCloudListDic"];
    if (!usersCloudListDic) {
        usersCloudListDic = [NSMutableDictionary dictionary];
    }
    NSMutableDictionary *newUsersCloudListDic = [NSMutableDictionary dictionaryWithDictionary:usersCloudListDic];
    
    NSMutableArray *newCloudList = [NSMutableArray array];
    for (NSDictionary *dic in cloudList) {
        NSMutableDictionary *newDic = [NSMutableDictionary dictionary];
        NSInteger ID = [dic integerValueForKey:@"id" defaultValue:-1];
        if (ID > 0) {
            [newDic setValue:[dic stringValueForKey:@"name" defaultValue:@""] forKey:@"name"];
            [newDic setValue:[dic stringValueForKey:@"mac" defaultValue:@""] forKey:@"mac"];
            [newDic setValue:@(ID) forKey:@"id"];
            [newDic setValue:[dic stringValueForKey:@"gps" defaultValue:@""] forKey:@"gps"];
            [newCloudList addObject:newDic];
        }
        
    }
    [newUsersCloudListDic setValue:newCloudList forKey:[NSString stringWithFormat:@"%zd", self.ID]];
    [defaults setObject:newUsersCloudListDic forKey:@"usersCloudListDic"];
    [defaults synchronize];
}

- (void)saveCloudListWithDevice:(DLDevice *)device {
    if (device) {
        NSMutableArray *cloudList = [NSMutableArray arrayWithArray:[self getCloudList]];
        NSMutableDictionary *newDeviceDic = [NSMutableDictionary dictionary];
        [newDeviceDic setValue:@(device.cloudID) forKey:@"id"];
        [newDeviceDic setValue:device.deviceName forKey:@"name"];
        [newDeviceDic setValue:device.getGps forKey:@"gps"];
        [newDeviceDic setValue:device.mac forKey:@"mac"];
        [cloudList addObject:[newDeviceDic copy]];
        [self saveCloudList:[cloudList copy]];
    }
}

- (void)removeDeviceByCloudList:(DLDevice *)device {
    if (device) {
        NSMutableArray *cloudList = [NSMutableArray arrayWithArray:[self getCloudList]];
        NSDictionary *removeDevice = nil;
        for (NSDictionary *deviceDic in cloudList) {
            NSString *mac = [deviceDic objectForKey:@"mac"];
            if ([mac isEqualToString:device.mac]) {
                removeDevice = deviceDic;
                break;
            }
        }
        if (removeDevice) {
            [cloudList removeObject:removeDevice];
            [self saveCloudList:[cloudList copy]];
        }
        
        // 删除该设备的离线信息
        [self removeDeviceOfflineInfo:device];
    }
}

- (NSArray *)getCloudList {
    if (self.ID <= 0) {
        return @[];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *usersCloudListDic = [defaults objectForKey:@"usersCloudListDic"];
    NSArray *cloudList = [usersCloudListDic arrayValueForKey:[NSString stringWithFormat:@"%zd", self.ID] defaultValue:@[]];
    return cloudList;
}

#pragma mark - 保存设备的离线信息
// 保存离线信息的字典格式：{"mac": {"offlineTime": 离线时间, "gps":离线位置， "name":离线名称}}
- (void)saveDeviceOfflineInfo:(DLDevice *)device {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *oldDeviceInfo = [defaults valueForKey:device.mac];
    if (!oldDeviceInfo) {
        oldDeviceInfo = [NSMutableDictionary dictionary];
    }
    NSMutableDictionary *newDeviceInfo = [NSMutableDictionary dictionaryWithDictionary:oldDeviceInfo];
    [newDeviceInfo setValue:[device offlineTime] forKey:@"offlineTime"];
    [newDeviceInfo setValue:[device getGps] forKey:@"gps"];
    [defaults setValue:newDeviceInfo forKey:device.mac];
    [defaults synchronize];
}

- (void)getDeviceOfflineInfo:(DLDevice *)device completion:(void (^)(NSString * offlineTime, NSString * gps))completion {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *oldDeviceInfo = [defaults valueForKey:device.mac];
    if (oldDeviceInfo) {
        NSString *offlineTime = [oldDeviceInfo valueForKey:@"offlineTime"];
        //        23.226792,113.304648
        NSString *gps = [oldDeviceInfo valueForKey:@"gps"];
        if (completion) {
            completion(offlineTime, gps);
        }
    }
    else {
        if (completion) {
            completion(nil, nil);
        }
    }
}

- (void)removeDeviceOfflineInfo:(DLDevice *)device {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:device.mac];
    [defaults synchronize];
}

- (void)saveDeviceName:(DLDevice *)device {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *oldDeviceInfo = [defaults valueForKey:device.mac];
    if (!oldDeviceInfo) {
        oldDeviceInfo = [NSMutableDictionary dictionary];
    }
    NSMutableDictionary *newDeviceInfo = [NSMutableDictionary dictionaryWithDictionary:oldDeviceInfo];
    [newDeviceInfo setValue:device.deviceName forKey:@"name"];
    [defaults setValue:newDeviceInfo forKey:device.mac];
    [defaults synchronize];
}

- (void)getDeviceName:(DLDevice *)device {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *oldDeviceInfo = [defaults valueForKey:device.mac];
    if (oldDeviceInfo) {
        NSString *name = [oldDeviceInfo valueForKey:@"name"];
        device.deviceName = name;
    }
}

#pragma mark - 保存地图是否需要显示用户位置的状态
- (void)saveUserLocationIsShow:(BOOL)showUserLocation {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:showUserLocation forKey:@"showUserLocation"];
    [defaults synchronize];
}

- (BOOL)getIsShowUserLocation {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *isExit = [defaults objectForKey:@"showUserLocation"];
    if (!isExit) {
        // 默认显示用户位置
        [defaults setBool:YES forKey:@"showUserLocation"];
        return YES;
    }
    return [defaults boolForKey:@"showUserLocation"];
}

#pragma mark - 手机报警
- (void)playSoundAlertMusic {
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
    NSString *musicPath = [[NSBundle mainBundle] pathForResource:alertMusic ofType:nil];
    NSURL *fileURL = [NSURL fileURLWithPath:musicPath];
    NSLog(@"fileURL = %@", fileURL.absoluteString);
    // 设置后台播放代码
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    // 这个进入后台10秒钟后播放没声音
//    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    // 这个可以在后台播放
    [audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
    [audioSession setActive:YES error:nil];
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    self.audioPlayer.delegate = self;
    self.audioPlayer.numberOfLoops = 1000;
    self.audioPlayer.volume = 1.0;
    [self.audioPlayer play];
    [self startSharkAnimation];
}

- (void)stopSoundAlertMusic {
    NSLog(@"停止查找手机的报警声音");
    [self.audioPlayer stop];
    [self stopSharkAnimation];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"监听到音乐结束");
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
    NSLog(@"监听到音乐开始被中断");
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player {
    NSLog(@"监听到音乐中断结束");
}

#pragma mark - 闪光灯动画
- (void)startSharkAnimation {
    [_sharkTimer setFireDate:[NSDate distantPast]];
}

- (void)stopSharkAnimation {
    [_sharkTimer setFireDate:[NSDate distantFuture]];
    [self closeSharkLight];
}

- (void)setupSharkLight {
    AVCaptureDevice *camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //修改前必须先锁定
    [camera lockForConfiguration:nil];
    //必须判定是否有闪光灯，否则如果没有闪光灯会崩溃
    if ([camera hasFlash]) {
        if (camera.flashMode == AVCaptureFlashModeOff || camera.flashMode == AVCaptureFlashModeAuto) {
            camera.flashMode = AVCaptureFlashModeOn;
            camera.torchMode = AVCaptureTorchModeOn;
        } else if (camera.flashMode == AVCaptureFlashModeOn) {
            camera.flashMode = AVCaptureFlashModeOff;
            camera.torchMode = AVCaptureTorchModeOff;
        }
        
    }
    [camera unlockForConfiguration];
}

- (void)closeSharkLight {
    AVCaptureDevice *camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //修改前必须先锁定
    [camera lockForConfiguration:nil];
    //必须判定是否有闪光灯，否则如果没有闪光灯会崩溃
    if ([camera hasFlash]) {
        camera.flashMode = AVCaptureFlashModeOff;
        camera.torchMode = AVCaptureTorchModeOff;
    }
    [camera unlockForConfiguration];
}

#pragma mark - 离线提示音
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
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)stopSound {
    if (soundID != -1) {
        AudioServicesDisposeSystemSoundID(soundID);
        AudioServicesRemoveSystemSoundCompletion(soundID);
        AudioServicesDisposeSystemSoundID(kSystemSoundID_Vibrate);
        AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate);
        soundID = -1;
    }
}

#pragma mark - 定位
- (void)uploadDeviceLocation:(DLDevice *)device {
    NSString *gps = [device getGps];
    if (gps.length == 0) {
        return;
    }
    NSLog(@"开始上传设备%@的位置, gps = %@", device.mac, gps);
    NSDictionary *body = @{@"deviceid":@(device.cloudID), @"gps":gps, @"action":@"updateDeviceGPS"};
    [InCommon sendHttpMethod:@"POST" URLString:@"http://121.12.125.214:1050/GetData.ashx" body:body completionHandler:^(NSURLResponse *response, NSDictionary *responseObject, NSError * _Nullable error) {
        if (error) {
            NSLog(@"上传设备位置失败: %@", error);
        }
        else {
            NSInteger code = [responseObject integerValueForKey:@"code" defaultValue:500];
            NSString *message = [responseObject stringValueForKey:@"message" defaultValue:@"gps更新失败"];
            NSLog(@"上传设备位置code = %zd, message = %@", code, message);
        }
    }];
}

- (NSString *)getCurrentGps{
    CLLocationCoordinate2D deviceLocation = self.currentLocation;
    NSString *gps = [NSString stringWithFormat:@"%f,%f", deviceLocation.latitude, deviceLocation.longitude];
    return gps;
}

- (BOOL)isOpensLocation {
    if (([CLLocationManager locationServicesEnabled]) &&
        ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways)) {
        return YES;
    }
    else {
        return NO;
    }
}

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

#pragma mark - 去到系统的APP设置界面
- (void)goToAPPSetupView {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if([[UIApplication sharedApplication] canOpenURL:url]) {
        NSURL*url =[NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    }
}

#pragma mark - 获取RSSI对应的图片名称
- (NSString *)getImageName:(NSNumber *)rssi {
    NSInteger rSSI = rssi.integerValue;
    NSString *imageName = @"RSSI_8";
    if(rSSI>-70)
    {
        imageName = @"RSSI_8";
    }
    else if(rSSI>-76)
    {
        imageName = @"RSSI_7";
    }
    else if(rSSI>-82)
    {
        imageName = @"RSSI_6";
    }
    else if(rSSI>-88)
    {
        imageName = @"RSSI_5";
    }
    else if(rSSI>-94)
    {
        imageName = @"RSSI_4";
    }
    else if(rSSI>-100)
    {
        imageName = @"RSSI_3";
    }
    else if(rSSI>-105)
    {
        imageName = @"RSSI_2";
    }
    else if(rSSI>-109)
    {
        imageName = @"RSSI_1";
    }
    else{
        imageName = @"RSSI_0";
    }
    return imageName;
}

#pragma mark - 获取设备所属类型
- (InDeviceType)getDeviceType:(CBPeripheral *)peripheral {
    if (!peripheral) {
        InDeviceNone;
    }
    InDeviceType deviceType = InDeviceNone;
    if ([peripheral.name isEqualToString:@"Innway Card"] || [peripheral.name isEqualToString:@"Lily"]) {
        deviceType = InDeviceCard;
    }
    else if ([peripheral.name isEqualToString:@"Innway Chip"]) {
        deviceType = InDeviceChip;
    } else if ([peripheral.name isEqualToString:@"Innway Tag"]) {
        deviceType = InDeviceTag;
    }
    return deviceType;
}

// 发送通知消息
- (void)sendLocalNotification:(NSString *)message {
    // 1.创建通知
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    // 2.设置通知的必选参数
    // 设置通知显示的内容
    localNotification.alertBody = message;
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

#pragma mark - HTTP
+ (void)sendHttpMethod:(NSString *)method URLString:(NSString *)URLString body:(NSDictionary *)body completionHandler:(nullable void (^)(NSURLResponse *response, NSDictionary *responseObject,  NSError * _Nullable error))completionHandler {
    if (URLString.length == 0) {
        URLString = @"http://121.12.125.214:1050/GetData.ashx";
    }
    NSMutableURLRequest* formRequest = [[AFHTTPRequestSerializer serializer] requestWithMethod:method URLString:URLString parameters:body error:nil];
    [formRequest setValue:@"application/x-www-form-urlencoded; charset=utf-8"forHTTPHeaderField:@"Content-Type"];
    AFHTTPSessionManager*manager = [AFHTTPSessionManager manager];
    AFJSONResponseSerializer* responseSerializer = [AFJSONResponseSerializer serializer];
    [responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"application/json",@"text/json",@"text/javascript",@"text/html",@"text/plain",nil]];
    manager.responseSerializer= responseSerializer;
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:formRequest uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse *_Nonnull response,id _Nullable responseObject,NSError *_Nullable error) {
        if (error) {
            error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:@{NSLocalizedDescriptionKey:@"网络连接异常"}];
        }
        completionHandler(response, responseObject, error);
    }];
    [dataTask resume];
}

#pragma mark - 判断是否刘海屏
+ (BOOL)isIPhoneX {
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    if (screenHeight >= 812) {
        return YES;
    }
    return NO;
}

#pragma mark - 设置导航栏图片
+ (void)setNavgationBar:(UINavigationBar *)bar {
    NSString *imageName = @"narBarBackgroudImage5s.jpg";
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    if (screenSize.width == 375 && screenSize.height == 667) {
        // Iphone6/7/8
        imageName = @"narBarBackgroudImage7.jpg";
    }
    else if (screenSize.width == 414 && screenSize.height == 736) {
        //Iphone6p/7p/8p
        imageName = @"narBarBackgroudImage8.jpg";
    }
    else if (screenSize.width == 375 && screenSize.height == 812) {
        // IphoneX
        imageName = @"narBarBackgroudImageX.jpg";
    }
    else if (screenSize.width == 414 && screenSize.height == 896) {
        // IphoneXR
        imageName = @"narBarBackgroudImageXR.jpg";
    }
    UIImage *backgroundImage = [UIImage imageNamed:imageName];
    backgroundImage = [backgroundImage resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch];
    
    [bar setBackgroundImage:backgroundImage forBarMetrics:UIBarMetricsDefault];
}

#pragma mark - date
//获取当前的时间 1980-01-01 00:00:01
- (NSString *)getCurrentTime{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSDate *datenow = [NSDate date];
    NSString *currentTimeString = [formatter stringFromDate:datenow];
    return currentTimeString;
}

// 字符串转换为日期  字符串格式：1980-01-01 00:00:01
- (NSDate *)dateFromStr:(NSString *)str {
    NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];//实例化一个NSDateFormatter对象
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];//设定时间格式,这里可以设置成自己需要的格式
    NSDate *date =[dateFormat dateFromString:str];
    return date;
}

// 字符串转换为日期
- (NSString *)dateStrFromDate:(NSDate *)date {
    NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];//实例化一个NSDateFormatter对象
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];//设定时间格式,这里可以设置成自己需要的格式
    NSString *currentDateStr = [dateFormat stringFromDate:date];
    return currentDateStr;
}


//  入参是NSDate类型
- (int)compareOneDate:(NSDate *)oneDate withAnotherDate:(NSDate *)anotherDate
{
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"dd-MM-yyyy HH:mm:ss"];
    
    NSString *oneDayStr = [df stringFromDate:oneDate];
    
    NSString *anotherDayStr = [df stringFromDate:anotherDate];
    
    NSDate *dateA = [df dateFromString:oneDayStr];
    
    NSDate *dateB = [df dateFromString:anotherDayStr];
    
    NSComparisonResult result = [dateA compare:dateB];
    
    if (result == NSOrderedAscending)
    {  // oneDate < anotherDate
        return 1;
        
    }else if (result == NSOrderedDescending)
    {  // oneDate > anotherDate
        return -1;
    }
    
    // oneDate = anotherDate
    return 0;
}

//  入参是NSString类型
- (int)compareOneDateStr:(NSString *)oneDateStr withAnotherDateStr:(NSString *)anotherDateStr
{
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDate *dateA = [[NSDate alloc]init];
    
    NSDate *dateB = [[NSDate alloc]init];
    
    dateA = [df dateFromString:oneDateStr];
    
    dateB = [df dateFromString:anotherDateStr];
    
    NSComparisonResult result = [dateA compare:dateB];
    
    if (result == NSOrderedAscending)
    {  // oneDateStr < anotherDateStr
        return 1;
        
    }else if (result == NSOrderedDescending)
    {  // oneDateStr > anotherDateStr
        return -1;
    }
    
    // oneDateStr = anotherDateStr
    return 0;
}


- (NSDateComponents *)differentWithDate:(NSString *)expireDateStr{
    NSDateFormatter *dateFomatter = [[NSDateFormatter alloc] init];
    dateFomatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    // 当前时间字符串格式
    NSDate *nowDate = [NSDate date];
    // 截止时间data格式
    NSDate *expireDate = [dateFomatter dateFromString:expireDateStr];
    // 当前日历
    NSCalendar *calendar = [NSCalendar currentCalendar];
    // 需要对比的时间数据
    NSCalendarUnit unit = NSCalendarUnitYear | NSCalendarUnitMonth
    | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    // 对比时间差
    NSDateComponents *dateCom = [calendar components:unit fromDate:expireDate toDate:nowDate options:0];
//    NSLog(@"dateCom.year = %zd, dateCom.month = %zd, dateCom.day = %zd, dateCom.hour = %zd, dateCom.minute = %zd, dateCom.second = %zd", dateCom.year, dateCom.month, dateCom.day, dateCom.hour, dateCom.minute, dateCom.second);
    return dateCom;
}

// 从16进制字符串获取10进制数值
- (NSInteger)getIntValueByHex:(NSString *)getStr
{
    NSScanner *tempScaner=[[NSScanner alloc] initWithString:getStr];
    uint32_t tempValue;
    [tempScaner scanHexInt:&tempValue];
    return tempValue;
}

@end

static inline id gizGetObjectFromDict(NSDictionary *dict, Class class, NSString *key, id defaultValue) { //通用安全方法
    if (![key isKindOfClass:[NSString class]] || ![dict isKindOfClass:[NSDictionary class]]) {
        return defaultValue;
    }
    
    id obj = dict[key];
    if ([obj isKindOfClass:class]) {
        return obj;
    }
    return defaultValue;
}

@implementation NSDictionary (GetValue)

- (NSString *)stringValueForKey:(NSString *)key defaultValue:(NSString *)defaultValue {
    return gizGetObjectFromDict(self, [NSString class], key, defaultValue);
}

- (NSNumber *)numberValueForKey:(NSString *)key defaultValue:(NSNumber *)defaultValue {
    return gizGetObjectFromDict(self, [NSNumber class], key, defaultValue);
}

- (NSInteger)integerValueForKey:(NSString *)key defaultValue:(NSInteger)defaultValue {
    NSNumber *number = gizGetObjectFromDict(self, [NSNumber class], key, @(defaultValue));
    return [number integerValue];
}

- (BOOL)boolValueForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
    NSNumber *number = gizGetObjectFromDict(self, [NSNumber class], key, @(defaultValue));
    return [number boolValue];
}

- (double)doubleValueForKey:(NSString *)key defaultValue:(double)defaultValue {
    NSNumber *number = gizGetObjectFromDict(self, [NSNumber class], key, @(defaultValue));
    return [number doubleValue];
}

- (NSArray *)arrayValueForKey:(NSString *)key defaultValue:(NSArray *)defaultValue {
    return gizGetObjectFromDict(self, [NSArray class], key, defaultValue);
}

- (NSDictionary *)dictValueForKey:(NSString *)key defaultValue:(NSDictionary *)defaultValue {
    return gizGetObjectFromDict(self, [NSDictionary class], key, defaultValue);
}

@end

@implementation InAlertTool

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

@interface InAlertView ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *confirmMessageLabel;
@property (weak, nonatomic) IBOutlet UILabel *confirmCancelMessageLabel;
@property (weak, nonatomic) IBOutlet UIButton *confirmBtn;
@property (weak, nonatomic) IBOutlet UIView *confirmAlertView;
@property (weak, nonatomic) IBOutlet UIView *confirmCancelAlertView;
@property (nonatomic, strong) confirmHanler confirmHanler;
@property (nonatomic, strong) confirmHanler cancleHanler;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *confirmBtnWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cancelBtnWidthConstraint;


@end

@implementation InAlertView

- (instancetype)init {
    if (self = [super init]) {
        self = [[[NSBundle mainBundle] loadNibNamed:@"InAlertView" owner:self options:nil] lastObject];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message confirm:(confirmHanler)confirmHanler {
    if (self = [self init]) {
        self.confirmCancelAlertView.hidden = YES;
        self.confirmAlertView.backgroundColor = [UIColor whiteColor];
        self.confirmAlertView.layer.cornerRadius = 5.0;
        self.titleLabel.text = title;
        self.confirmMessageLabel.text = message;
        self.confirmHanler = confirmHanler;
        //        [self.confirmBtn setTitle:confirm forState:UIControlStateNormal];
    }
    return self;
}

- (instancetype)initWithMessage:(NSString *)message confirm:(confirmHanler)confirmHanler cancleHanler:(confirmHanler)cancleHanler{
    if (self = [self init]) {
        self.confirmAlertView.hidden = YES;
        self.confirmCancelAlertView.backgroundColor = [UIColor whiteColor];
        self.confirmCancelAlertView.layer.cornerRadius = 5.0;
        //        self.titleLabel.text = title;
        self.confirmCancelMessageLabel.text = message;
        self.confirmHanler = confirmHanler;
        self.cancleHanler = cancleHanler;
        //        [self.confirmBtn setTitle:confirm forState:UIControlStateNormal];
        if ([UIScreen mainScreen].bounds.size.width == 320) {
            self.confirmBtnWidthConstraint.constant = 110;
            self.cancelBtnWidthConstraint.constant = 110;
        }
    }
    return self;
}

+ (InAlertView *)showAlertWithTitle:(NSString *)title message:(NSString *)message confirmHanler:(confirmHanler)confirmHanler {
    InAlertView *alertView = [[InAlertView alloc] initWithTitle:title message:message confirm:confirmHanler];
    [alertView show];
    return alertView;
}

+ (InAlertView *)showAlertWithMessage:(NSString *)message confirmHanler:(confirmHanler)confirmHanler cancleHanler:(confirmHanler)cancleHanler; {
    InAlertView *alertView = [[InAlertView alloc] initWithMessage:message confirm:confirmHanler cancleHanler:cancleHanler];
    [alertView show];
    return alertView;
}

- (void)show {
    UIWindow *rootWindow = [UIApplication sharedApplication].keyWindow;
    [rootWindow addSubview:self];
    self.frame = [UIScreen mainScreen].bounds;
}

- (IBAction)confirmDidClick {
    [self removeFromSuperview];
    if (self.confirmHanler) {
        self.confirmHanler();
    }
}

- (IBAction)cancleDidClick {
    [self removeFromSuperview];
    if (self.cancleHanler) {
        self.cancleHanler();
    }
}

@end
