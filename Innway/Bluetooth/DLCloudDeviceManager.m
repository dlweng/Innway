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
@interface DLCloudDeviceManager()

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
        peripheralName = @"Card";
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
                    device.rssi = knowDevice.rssi;
                }
                device.mac = mac;
                device.cloudID = [cloudDevice integerValueForKey:@"id" defaultValue:-1];
                device.deviceName = [cloudDevice stringValueForKey:@"name" defaultValue:@""];
                device.coordinate = [cloudDevice stringValueForKey:@"gps" defaultValue:@""];
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
//        if (peripheral) {
//            NSLog(@"设置peripheral--更新设备mac, peripheral = %@", peripheral);
//        }
        device.peripheral = peripheral;
        device.rssi = knowDevice.rssi;
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

- (NSMutableDictionary<NSString *,DLDevice *> *)cloudDeviceList {
    if (!_cloudDeviceList) {
        _cloudDeviceList = [NSMutableDictionary dictionary];
    }
    return _cloudDeviceList;
}

//- (void)addDevice:(NSString *)mac completion:(DidAddDeviceEvent)completion {
//    if (self.cloudDeviceList.count >= 8) {
//        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:300 userInfo:@{NSLocalizedDescriptionKey:@"添加的设备不能大于8个"}];
//        completion(self, nil, error);
//        return;
//    }
//    DLDevice *device = [self.cloudDeviceList objectForKey:mac];
//    if (device) {
//        // 已经添加到云端
//        if (device.connected && device.online) {
//            // 已经连接，直接跳转
//            NSLog(@"设备已经存在云端，也已连接，直接跳转");
//            [device discoverServices];
//            if (completion) {
//                completion(self, device, nil);
//            }
//            return;
//        }
//        else {
//            //未连接，去连接
//            NSLog(@"设备已添加到云端，但是未连接，下一步做连接");
//            [self connectDevice:device mac:mac completion:completion];
//        }
//    }
//    else {
//        NSLog(@"未添加到云端，需做请求添加");
//        // 未添加到云端, 添加到云端
//        DLKnowDevice *knowDevice = [[DLCentralManager sharedInstance].knownPeripherals objectForKey:mac];
//        CBPeripheral *peripheral = knowDevice.peripheral;
//        NSString *peripheralName = peripheral.name;
//        if (peripheralName.length == 0) {
//            peripheralName = @"Lily";
//        }
//        NSDictionary *body = @{@"userid":@([InCommon sharedInstance].ID), @"name":peripheralName, @"mac":mac, @"action":@"addDevice", @"gps":[common getCurrentGps]};
//        [InCommon sendHttpMethod:@"POST" URLString:@"http://121.12.125.214:1050/GetData.ashx" body:body completionHandler:^(NSURLResponse *response, NSDictionary *responseObject, NSError * _Nullable error) {
//            if (error) {
//                NSLog(@"添加设备http网络异常, %@",error);
//                completion(self, nil, error);
//                return ;
//            }
//            NSInteger code = [responseObject integerValueForKey:@"code" defaultValue:500];
//            if (code == 200) {
//                NSInteger data = [responseObject integerValueForKey:@"data" defaultValue:-1];
//                if (data > -1) {
//                    NSLog(@"添加设备http请求成功");
//                    // 创建对象
//                    DLDevice *newDevice = [DLDevice device:peripheral];
//                    newDevice.cloudID = data;
//                    newDevice.mac = mac;
//                    // 添加到云端列表
//                    [self.cloudDeviceList setValue:newDevice forKey:mac];
//                    //去连接设备
//                    [self connectDevice:newDevice mac:mac completion:completion];
//                    return ;
//                }
//            }
//
//            NSString *message = [responseObject stringValueForKey:@"message" defaultValue:@"添加设备http网络异常"];
//            NSError *myError = [NSError errorWithDomain:NSStringFromClass([self class]) code:code userInfo:@{NSLocalizedDescriptionKey: message}];
//            NSLog(@"添加设备http请求失败, %@",message);
//            completion(self, nil, myError);
//        }];
//    }
//}

//- (void)connectDevice:(DLDevice *)device mac:(NSString *)mac  completion:(DidAddDeviceEvent)completion {
//    __block BOOL find = NO;
//    [self.centralManager startScanDeviceWithTimeout:5 discoverEvent:^(DLCentralManager *manager, CBPeripheral *peripheral, NSString *newMac) {
//        if (find) {
//            return ;
//        }
//        if ([newMac isEqualToString:mac]) {
//            find = YES;
//            NSLog(@"查找到设备, peripheral = %@",  peripheral);
//            //2.再连接设备
//            if (peripheral.state == CBPeripheralStateConnecting || peripheral.state == CBPeripheralStateConnected) {
//                // 不清楚新查找的设备，为何有存在连接状态的，导致去连接没有回调，这里处理这种情况的
//                NSLog(@"查找到的新设备处于连接状态");
//                [device discoverServices];
//                completion(self, device, nil);
//                return;
//            }
//            [self.centralManager connectToDevice:peripheral completion:^(DLCentralManager *manager, CBPeripheral *peripheral, NSError *error) {
//                if (error) {
//                    // 连接失败
//                    completion(self, nil, error);
//                    return ;
//                }
//                //连接成功,发现服务
//                NSLog(@"添加设备-扫描发现了设备:%@", mac);
//                [device discoverServices];
//                completion(self, device, nil);
//            }];
//        }
//    } didEndDiscoverDeviceEvent:^(DLCentralManager *manager, NSMutableDictionary<NSString *,DLKnowDevice *> *knownPeripherals) {
//        if (find) {
//            return ;
//        }
//        DLKnowDevice *knowDevice = [knownPeripherals objectForKey:mac];
//        if (knowDevice) {
//            find = YES;
//            CBPeripheral *peripheral = knowDevice.peripheral;
//            NSLog(@"查找到设备, peripheral = %@",  peripheral);
//            //2.再连接设备
//            if (peripheral.state == CBPeripheralStateConnecting || peripheral.state == CBPeripheralStateConnected) {
//                // 不清楚新查找的设备，为何有存在连接状态的，导致去连接没有回调，这里处理这种情况的
//                NSLog(@"查找到的新设备处于连接状态");
//                [device discoverServices];
//                completion(self, device, nil);
//                return;
//            }
//            [self.centralManager connectToDevice:peripheral completion:^(DLCentralManager *manager, CBPeripheral *peripheral, NSError *error) {
//                if (error) {
//                    // 连接失败
//                    completion(self, nil, error);
//                    return ;
//                }
//                //连接成功,发现服务
//                NSLog(@"添加设备-扫描发现了设备:%@", mac);
//                [device discoverServices];
//                completion(self, device, nil);
//            }];
//            return;
//        }
//        // 扫描不到设备
//        NSError *error = [NSError errorWithDomain:NSStringFromClass([manager class]) code:-3 userInfo:@{NSLocalizedDescriptionKey:@"查找不到设备"}];
//        NSLog(@"添加设备-扫描不到设备:%@", mac);
//        if (completion) {
//            completion(self, nil, error);
//        }
//        return;
//    }];
//}

@end
