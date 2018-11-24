//
//  DLCloudDeviceManager.m
//  Bluetooth
//
//  Created by danly on 2018/8/19.
//  Copyright © 2018年 date. All rights reserved.
//

#import "DLCloudDeviceManager.h"
#import "InCommon.h"


static DLCloudDeviceManager *instance = nil;
@interface DLCloudDeviceManager() {
    NSTimer *_getDeviceInfoTimer;
    NSTimer *_readRSSITimer; //所有设备要统一读RSSI值，所以，放到这里来做
}

@property (nonatomic, weak) DLCentralManager *centralManager;

@end

@implementation DLCloudDeviceManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.centralManager = [DLCentralManager sharedInstance];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        // 在初始化云端管理对象30秒之后，每10分钟获取一次设备的状态
        _getDeviceInfoTimer = [NSTimer timerWithTimeInterval:600 target:self selector:@selector(autoGetDeviceInfo) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_getDeviceInfoTimer forMode:NSRunLoopCommonModes];
        __weak typeof(NSTimer *) weakTimer = _getDeviceInfoTimer;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakTimer setFireDate:[NSDate distantPast]];
        });
        
        // 初始化1秒扫描一次RSSI的定时器
        _readRSSITimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(getDevicesRSSI) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_readRSSITimer forMode:NSRunLoopCommonModes];
        [_readRSSITimer setFireDate:[NSDate distantPast]];
    }
    return self;
}

- (void)addDevice:(NSString *)mac completion:(DidAddDeviceEvent)completion {
    if (self.cloudDeviceList.count >= 8) {
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:300 userInfo:@{NSLocalizedDescriptionKey:@"添加的设备不能大于8个"}];
        completion(self, nil, error);
        return;
    }
    NSLog(@"未添加到云端，需做请求添加");
    // 未添加到云端, 添加到云端
    DLKnowDevice *knowDevice = [[DLCentralManager sharedInstance].knownPeripherals objectForKey:mac];
    CBPeripheral *peripheral = knowDevice.peripheral;
    NSString *peripheralName = peripheral.name;
    if (peripheralName.length == 0 || [peripheralName isEqualToString:@"Lily"]) {
        peripheralName = @"Innway Card";
    }
    NSDictionary *body = @{@"userid":@([InCommon sharedInstance].ID), @"name":peripheralName, @"mac":mac, @"action":@"addDevice", @"gps":[common getCurrentGps]};
    [InCommon sendHttpMethod:@"POST" URLString:@"http://121.12.125.214:1050/GetData.ashx" body:body completionHandler:^(NSURLResponse *response, NSDictionary *responseObject, NSError * _Nullable error) {
        if (error) {
            NSLog(@"添加设备mac:%@, 网络异常, %@", mac, error);
            completion(self, nil, error);
            return ;
        }
        NSInteger code = [responseObject integerValueForKey:@"code" defaultValue:500];
        if (code == 200) {
            NSInteger data = [responseObject integerValueForKey:@"data" defaultValue:-1];
            if (data > -1) {
//                NSLog(@"添加设备http请求成功");
                // 创建对象
                DLDevice *newDevice = [DLDevice device:peripheral];
                newDevice.type = [common getDeviceType:peripheral];
                newDevice.cloudID = data;
                newDevice.mac = mac;
                // 添加到云端列表
                [self.cloudDeviceList setValue:newDevice forKey:mac];
                [common saveCloudListWithDevice:newDevice];
                [newDevice connectToDevice:nil]; // 自动建立与设备的连接
                completion(self, newDevice, nil);
                return ;
            }
        }
        
        NSString *message = [responseObject stringValueForKey:@"message" defaultValue:@"添加设备http网络异常"];
        NSError *myError = [NSError errorWithDomain:NSStringFromClass([self class]) code:code userInfo:@{NSLocalizedDescriptionKey: message}];
        NSLog(@"添加设备http请求失败, %@",message);
        completion(self, nil, myError);
    }];
}

- (void)deleteDevice:(NSString *)mac completion:(DidDeleteDeviceEvent)completion {
    NSLog(@"删除设备mac：%@", mac);
    // 1.从云端删除设备
    // 2.断开连接
    DLDevice *device = [self.cloudDeviceList objectForKey:mac];
    if (device) {
        NSDictionary *body = @{@"deviceid":@(device.cloudID), @"action":@"deleteDevice"};
        [InCommon sendHttpMethod:@"POST" URLString:@"http://121.12.125.214:1050/GetData.ashx" body:body completionHandler:^(NSURLResponse *response, NSDictionary *responseObject, NSError * _Nullable error) {
            if (error) {
                NSLog(@"做http请求删除失败, %@", error);
                completion(self, error);
            }
            else {
                NSInteger code = [responseObject integerValueForKey:@"code" defaultValue:500];
                if (code == 200) {
                    device.cloudID = -1; // 标识设备已经被删除
                    // 更新本地保存的设备列表
                    [common removeDeviceByCloudList:device];
//                    NSLog(@"http请求删除设备成功");
                    [self.cloudDeviceList removeObjectForKey:mac];
                    [device disConnectToDevice:^(DLDevice *deletedDvice, NSError *error) {
                        if (error) {
                            NSError *myError = [NSError errorWithDomain:NSStringFromClass([self class]) code:-4 userInfo:@{NSLocalizedDescriptionKey: @"断开设备连接失败"}];
                            completion(self, myError);
                            return ;
                        }
                        completion(self, nil);
                    }];
                }
                else {
                    NSString *message = [responseObject stringValueForKey:@"message" defaultValue:@"删除设备失败"];
                    NSError *myError = [NSError errorWithDomain:NSStringFromClass([self class]) code:code userInfo:@{NSLocalizedDescriptionKey: message}];
                    NSLog(@"http请求删除设备失败， %@", message);
                    completion(self, myError);
                }
            }
        }];
    }
    else {
        NSLog(@"云端列表不存在该设备，不做删除动作, %@", self.cloudDeviceList);
        completion(self, nil);
    }
    
}

// 获取云端的设备列表
- (void)getHTTPCloudDeviceListCompletion:(DidGetCloudListEvent)completion {
    NSLog(@"做请求去获取云端的设备列表");
    NSDictionary *body = @{@"userid":@([InCommon sharedInstance].ID), @"action":@"getDeviceList"};
    [InCommon sendHttpMethod:@"POST" URLString:@"http://121.12.125.214:1050/GetData.ashx" body:body completionHandler:^(NSURLResponse *response, NSDictionary *responseObject, NSError * _Nullable error) {
        NSArray *cloudDevices;
        if (error) {
            cloudDevices = [common getCloudList];
            NSLog(@"获取云端设备列表失败: %@", error);
        }
        else {
            NSInteger code = [responseObject integerValueForKey:@"code" defaultValue:500];
            if (code == 200) {
                cloudDevices = [responseObject arrayValueForKey:@"data" defaultValue:nil];
                NSLog(@"获取云端列表成功: %@", cloudDevices.description);
                if (cloudDevices.count > 0) {
                    // 保存本地云端列表
                    [common saveCloudList:cloudDevices];
                }
            }
            else {
                NSLog(@"获取云端设备列表失败: %@", [responseObject stringValueForKey:@"message" defaultValue:@""]);
                cloudDevices = [common getCloudList];
            }
        }
        if (cloudDevices.count > 0) {
            NSMutableDictionary *newList = [NSMutableDictionary dictionary];
            for (NSDictionary *cloudDevice in cloudDevices) {
                NSString *mac = [cloudDevice stringValueForKey:@"mac" defaultValue:@""];
                DLDevice *device = [self.cloudDeviceList objectForKey:mac];
                if (!device) {
                    // 不存在，则需要创建
                    DLKnowDevice *knowDevice = [self.centralManager.knownPeripherals objectForKey:mac];
                    CBPeripheral *peripheral = knowDevice.peripheral;
                    device = [DLDevice device:peripheral];
#warning  从云端获取设备的类型 云端还没做，默认是card类型
                    device.type = InDeviceCard;
                }
                device.mac = mac;
                device.cloudID = [cloudDevice integerValueForKey:@"id" defaultValue:-1];
                device.deviceName = [cloudDevice stringValueForKey:@"name" defaultValue:@""];
                device.coordinate = [cloudDevice stringValueForKey:@"gps" defaultValue:@""];
                // 获取本地保存的离线信息和设备名称
                [common getDeviceName:device];
                [common getDeviceOfflineInfo:device completion:^(NSString *offlineTime, NSString *gps) {
                    if (offlineTime) {
                        device.offlineTime = offlineTime;
                    }
                    else {
                        // 没有掉线信息，将当前时间当成掉线时间
                        device.offlineTime = [common getCurrentTime];
                    }
                    if (gps) {
                        device.coordinate = gps;
                    }
                    else {
                        // 获取当前的位置
                        device.coordinate = [common getCurrentGps];
                    }
                    if (!offlineTime || !gps) {
                        // 如果没有掉线信息，存一份掉线信息
                        [common saveDeviceOfflineInfo:device];
                    }
                }];
                [newList setValue:device forKey:mac];
            }
            self.cloudDeviceList = newList;
        }
        completion(self, [self.cloudDeviceList copy]);
    }];
    
}

//根据新发现的设备更新云端列表
- (void)updateCloudList {
    for (NSString *mac in self.cloudDeviceList.allKeys) {
        DLDevice *device = self.cloudDeviceList[mac];
        DLKnowDevice *knowDevice = [self.centralManager.knownPeripherals objectForKey:mac];
        CBPeripheral *peripheral = knowDevice.peripheral;
        device.peripheral = peripheral;
    }
    [self autoConnectCloudDevice];
}

// 自动连接云端的设备
- (void)autoConnectCloudDevice {
    for (NSString *mac in self.cloudDeviceList.allKeys) {
        DLDevice *device = self.cloudDeviceList[mac];
        if (device.peripheral && !device.connected) {
            [device connectToDevice:nil];
        }
    }
}

- (void)deleteCloudList {
    for (NSString *mac in self.cloudDeviceList) {
        DLDevice *device = [self.cloudDeviceList objectForKey:mac];
        if (device.connected) {
            //断开所有已经连接的设备
            NSLog(@"断开设备的连接: %@", device.peripheral);
            [self.centralManager disConnectToDevice:device.peripheral completion:nil];
        }
    }
    [self.cloudDeviceList removeAllObjects];
}

- (void)autoGetDeviceInfo {
    for (NSString *mac in self.cloudDeviceList.allKeys) {
        DLDevice *device = self.cloudDeviceList[mac];
        [device getDeviceInfo];
    }
}

- (void)getDevicesRSSI {
    for (NSString *mac in self.cloudDeviceList.allKeys) {
        DLDevice *device = self.cloudDeviceList[mac];
        [device readRSSI];
    }
}

- (void)dealloc {
    //移除扫描RSSI定时器
    [_readRSSITimer invalidate];
    _readRSSITimer = nil;
    
    [_getDeviceInfoTimer invalidate];
    _getDeviceInfoTimer = nil;
}


- (NSMutableDictionary<NSString *,DLDevice *> *)cloudDeviceList {
    if (!_cloudDeviceList) {
        _cloudDeviceList = [NSMutableDictionary dictionary];
    }
    return _cloudDeviceList;
}

@end
