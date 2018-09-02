//
//  DLCloudDeviceManager.m
//  Bluetooth
//
//  Created by danly on 2018/8/19.
//  Copyright © 2018年 date. All rights reserved.
//

#import "DLCloudDeviceManager.h"
#import <AFNetworking.h>
#import "InCommon.h"

static DLCloudDeviceManager *instance = nil;
static BOOL deleteing = NO;
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
    if (self.cloudDeviceList.count >= 6) {
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:6 userInfo:nil];
        completion(self, nil, error);
        return;
    }
    DLDevice *device = [self.cloudDeviceList objectForKey:mac];
    if (device) {
        // 已经添加到云端
        if (device.connected) {
            // 已经连接，直接跳转
            NSLog(@"设备已经存在云端，也已连接，直接跳转");
            [device discoverServices];
            if (completion) {
                completion(self, device, nil);
            }
            return;
        }
        else {
            //未连接，去连接
            NSLog(@"设备已添加到云端，但是未连接，下一步做连接");
            [self connectDevice:device mac:mac completion:completion];
        }
    }
    else {
        NSLog(@"未添加到云端，需做请求添加");
        // 未添加到云端, 添加到云端
        DLKnowDevice *knowDevice = [[DLCentralManager sharedInstance].knownPeripherals objectForKey:mac];
        CBPeripheral *peripheral = knowDevice.peripheral;
        NSString *peripheralName = peripheral.name;
        if (peripheralName.length == 0) {
            peripheralName = @"Lily";
        }
        NSDictionary *parameters = @{@"userid":@([InCommon sharedInstance].ID), @"name":peripheralName, @"mac":mac};
        [[AFHTTPSessionManager manager] POST:@"http://111.230.192.125/device/addDevice" parameters:parameters  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (responseObject) {
                NSLog(@"做添加http请求成功");
                NSString *deviceid = [responseObject stringValueForKey:@"deviceid" defaultValue:@""];
                // 创建对象
                DLDevice *newDevice = [DLDevice device:peripheral];
                newDevice.cloudID = deviceid;
                newDevice.mac = mac;
                
                // 添加到云端列表
                [self.cloudDeviceList setValue:newDevice forKey:mac];
                //去连接设备
                [self connectDevice:newDevice mac:mac completion:completion];
                
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"做添加http请求失败, %@",error);
            //创建失败
            completion(self, nil, error);
        }];
    }
}

- (void)connectDevice:(DLDevice *)device mac:(NSString *)mac  completion:(DidAddDeviceEvent)completion {
    __block BOOL find = NO;
    [self.centralManager startScanDeviceWithTimeout:10 discoverEvent:^(DLCentralManager *manager, CBPeripheral *peripheral, NSString *newMac) {
        if (find) {
            return ;
        }
        if ([newMac isEqualToString:mac]) {
            find = YES;
            NSLog(@"查找到设备, peripheral = %@",  peripheral);
            //2.再连接设备
            if (peripheral.state == CBPeripheralStateConnecting || peripheral.state == CBPeripheralStateConnected) {
                // 不清楚新查找的设备，为何有存在连接状态的，导致去连接没有回调，这里处理这种情况的
                NSLog(@"查找到的新设备处于连接状态");
                [device discoverServices];
                completion(self, device, nil);
                return;
            }
            [self.centralManager connectToDevice:peripheral completion:^(DLCentralManager *manager, CBPeripheral *peripheral, NSError *error) {
                if (error) {
                    // 连接失败
                    completion(self, nil, error);
                    return ;
                }
                //连接成功,发现服务
                NSLog(@"添加设备-扫描发现了设备:%@", mac);
                [device discoverServices];
                completion(self, device, nil);
            }];
        }
    } didEndDiscoverDeviceEvent:^(DLCentralManager *manager, NSMutableDictionary<NSString *,DLKnowDevice *> *knownPeripherals) {
        if (find) {
            return ;
        }
        // 扫描不到设备
        NSError *error = [NSError errorWithDomain:NSStringFromClass([manager class]) code:2 userInfo:nil];
        NSLog(@"添加设备-扫描不到设备:%@", mac);
        if (completion) {
            completion(self, nil, error);
        }
        return;
    }];
}

- (void)deleteDevice:(NSString *)mac completion:(DidDeleteDeviceEvent)completion {
    NSLog(@"删除设备mac：%@", mac);
    deleteing = YES;
    // 1.从云端删除设备
    // 2.断开连接
    DLDevice *device = [self.cloudDeviceList objectForKey:mac];
    if (device) {
        NSDictionary *parameters = @{@"deviceid":device.cloudID};
        [[AFHTTPSessionManager manager] POST:@"http://111.230.192.125/device/deleteDevice" parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"做http请求删除成功, %@", responseObject);
            if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
                NSNumber *code = responseObject[@"code"];
                NSString *message = responseObject[@"message"];
                if (code.integerValue == 200) {
                    [self.cloudDeviceList removeObjectForKey:mac];
                    [self.centralManager disConnectToDevice:device.peripheral completion:^(DLCentralManager *manager, CBPeripheral *peripheral, NSError *error) {
                        if (deleteing && [device.peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
                            deleteing = NO;
                            if (error) {
                                NSLog(@"断开连接失败，不做删除, %@", error);
                                completion(self, error);
                                return ;
                            }
                            completion(self, nil);
                        }
                    }];
                }
                else {
                    NSLog(@"删除失败, %@", message);
                    NSError *error = [NSError errorWithDomain:NSStringFromClass([DLCloudDeviceManager class]) code:1 userInfo:nil];
                    completion(self, error);
                }
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"做http请求删除失败, %@", error);
            completion(self, error);
        }];
    }
    else {
        NSLog(@"云端列表不存在该设备，不做删除动作, %@", self.cloudDeviceList);
        completion(self, nil);
    }
    
}

// 获取云端的设备列表
- (void)getHTTPCloudDeviceList {
    NSLog(@"做请求去获取云端的设备列表");
    NSDictionary *parameters = @{@"userid":@([InCommon sharedInstance].ID)};
    [[AFHTTPSessionManager manager] POST:@"http://111.230.192.125/device/getDeviceList" parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"获取云端设备列表成功: %@", responseObject);
        if (responseObject) {
            NSArray *cloudDevices = [responseObject arrayValueForKey:@"data" defaultValue:nil];
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
                        device.rssi = knowDevice.rssi;
                    }
                    device.mac = mac;
                    device.cloudID = [cloudDevice stringValueForKey:@"id" defaultValue:@""];
                    device.deviceName = [cloudDevice stringValueForKey:@"name" defaultValue:@""];
                    device.coordinate = [cloudDevice stringValueForKey:@"gps" defaultValue:@""];
                    [newList setValue:device forKey:mac];
                }
                self.cloudDeviceList = newList;
                [self autoConnectCloudDevice];
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"获取云端设备列表失败: %@", error);
    }];
}

//根据新发现的设备更新云端列表
- (void)updateCloudList {
    for (NSString *mac in self.cloudDeviceList.allKeys) {
        DLDevice *device = self.cloudDeviceList[mac];
        DLKnowDevice *knowDevice = [self.centralManager.knownPeripherals objectForKey:mac];
        CBPeripheral *peripheral = knowDevice.peripheral;
        NSLog(@"设置peripheral--更新设备mac, peripheral = %@", peripheral);
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
            [self.centralManager connectToDevice:device.peripheral completion:^(DLCentralManager *manager, CBPeripheral *peripheral, NSError *error) {
                if (!error) {
                    //成功连接，去发现服务
                    [device discoverServices];
                }
            }];
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

@end
