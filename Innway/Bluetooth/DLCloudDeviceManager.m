//
//  DLCloudDeviceManager.m
//  Bluetooth
//
//  Created by danly on 2018/8/19.
//  Copyright © 2018年 date. All rights reserved.
//

#import "DLCloudDeviceManager.h"

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
    DLDevice *device = [self.cloudDeviceList objectForKey:mac];
    if (device && (device.peripheral.state == CBPeripheralStateConnected || device.peripheral.state == CBPeripheralStateConnecting)) {
        [device discoverServices];
        if (completion) {
            completion(self, device, nil);
        }
        return;
    }
    //1.先扫描设备
    __block BOOL find = NO;
    [self.centralManager startScanDidDiscoverDeviceEvent:^(DLCentralManager *manager, CBPeripheral *peripheral, NSString *newMac) {
        if (find) {
            return ;
        }
        if ([newMac isEqualToString:mac]) {
            find = YES;
            //2.再连接设备
            [self.centralManager connectToDevice:peripheral completion:^(DLCentralManager *manager, CBPeripheral *peripheral, NSError *error) {
                if (error) {
                    // 连接失败
                    completion(self, nil, error);
                    return ;
                }
                //3. 连接成功, 查找或者创建对象
                DLDevice *device = [self.cloudDeviceList objectForKey:mac];
                if (!device) {
                    // 新设备需要添加到云端列表
                    device = [DLDevice device:peripheral];
                    device.mac = mac;
                    [self.cloudDeviceList setObject:device forKey:mac];
                }
                //4. 发现服务
                [device discoverServices];
                completion(self, device, nil);
            }];
        }
    } didEndDiscoverDeviceEvent:^(DLCentralManager *manager, NSMutableDictionary<NSString *,CBPeripheral *> *knownPeripherals) {
        if (find) {
            return ;
        }
        // 扫描不到设备
        NSError *error = [NSError errorWithDomain:NSStringFromClass([manager class]) code:2 userInfo:nil];
        if (completion) {
            completion(self, nil, error);
        }
        return;
    }];

    
    //5.添加设备到云端
    //6.成功，创建对象并发现服务
    //7.失败，断开连接,返回空设备
}

- (void)deleteDevice:(NSString *)mac completion:(DidDeleteDeviceEvent)completion {
    // 1.从云端删除设备
    // 2.断开连接
    DLDevice *device = [self.cloudDeviceList objectForKey:mac];
    if (device) {
        [self.centralManager disConnectToDevice:device.peripheral completion:^(DLCentralManager *manager, CBPeripheral *peripheral, NSError *error) {
            //默认断开连接一定成功
        }];
        // 3.删除掉云端列表的设备
        [self.cloudDeviceList removeObjectForKey:mac];
    }
    completion(self, nil);
}

- (NSMutableDictionary<NSString *,DLDevice *> *)cloudDeviceList {
    if (!_cloudDeviceList) {
        _cloudDeviceList = [NSMutableDictionary dictionary];
    }
    return _cloudDeviceList;
}

@end
