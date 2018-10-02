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
    if(rSSI>=-45)
    {
        imageName = @"RSSI_12";
    }
    else if(rSSI>-50)//>90%
    {
        imageName = @"RSSI_11";
    }
    else if(rSSI>-55)//>80%
    {
        imageName = @"RSSI_10";
    }
    else if(rSSI>-60)//>70%
    {
        imageName = @"RSSI_9";
    }
    else if(rSSI>-65)//>60%
    {
        imageName = @"RSSI_8";
    }
    else if(rSSI>-70)//>50%
    {
        imageName = @"RSSI_7";
    }
    else if(rSSI>-75)//>40%
    {
        imageName = @"RSSI_6";
    }
    else if(rSSI>-80)//>30%
    {
        imageName = @"RSSI_5";
    }
    else if(rSSI>-85)//>20%
    {
        imageName = @"RSSI_4";
    }
    else if(rSSI>-90)//>10%
    {
        imageName = @"RSSI_3";
    }
    else if(rSSI>-95)//>10%
    {
        imageName = @"RSSI_2";
    }
    else if(rSSI>-100)//>10%
    {
        imageName = @"RSSI_1";
    }
    else{
        imageName = @"RSSI_0";
    }
    return imageName;
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
