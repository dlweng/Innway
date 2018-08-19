//
//  DLBluetoothDeviceManager.m
//  Bluetooth
//
//  Created by danly on 2018/8/12.
//  Copyright © 2018年 date. All rights reserved.
//

#import "DLCentralManager.h"
#import "DLDevice.h"

static DLCentralManager *instance = nil;

@interface DLCentralManager()<CBCentralManagerDelegate>

@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) CentralManagerEvent startCompletion;
@property (nonatomic, strong) DidDiscoverDeviceEvent discoverDeviceCompletion;
@property (nonatomic, strong) DidConnectToDeviceEvent connectDeviceCompletion;
@property (nonatomic, strong) DidDisConnectToDeviceEvent disConnectDeviceCompletion;

@end

@implementation DLCentralManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - Interface
+ (void)startSDKCompletion:(CentralManagerEvent)completion {
    if (!instance) {
        NSLog(@"启动蓝牙SDK");
        instance = [self sharedInstance];
        instance.manager = [[CBCentralManager alloc] initWithDelegate:instance queue:dispatch_get_main_queue()];
        instance.startCompletion = completion;
    }
}

- (void)startScanCompletion:(DidDiscoverDeviceEvent)completion {
    NSLog(@"开启设备发现功能");
    // 只删除断开连接的设备
    NSMutableArray *disconnectKeys = [NSMutableArray array];
    for (NSString *identify in self.knownPeripherals.allKeys) {
        CBPeripheral *peripheral = self.knownPeripherals[identify];
        if (peripheral.state == CBPeripheralStateDisconnected) {
            [disconnectKeys addObject:identify];
        }
    }
    for (NSString *identify in disconnectKeys) {
        [self.knownPeripherals removeObjectForKey:identify];
    }
    // 开始扫描
    [self startScaning];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //扫描10秒停止
        [self stopScanning];
    });
    self.discoverDeviceCompletion = completion;
}

- (void)stopScanning {
    NSLog(@"关闭设备发现功能");
    [self.manager stopScan];
    if (self.discoverDeviceCompletion) {
        self.discoverDeviceCompletion(self, self.knownPeripherals);
    }
}

- (void)connectToDevice: (CBPeripheral *)peripheral completion:(DidConnectToDeviceEvent)completion {
    [self connectToPeripheral:peripheral];
    self.connectDeviceCompletion = completion;
}

- (void)disConnectToDevice: (CBPeripheral *)peripheral completion:(DidDisConnectToDeviceEvent)completion {
    NSLog(@"开始断开设备的连接: %@", peripheral);
    [self.manager cancelPeripheralConnection:peripheral];
    self.disConnectDeviceCompletion = completion;
}

#pragma mark - 内部工具方法
- (void)startScaning {
    [self.manager scanForPeripheralsWithServices:nil options:nil];
}

- (void)connectToPeripheral:(CBPeripheral *)peripheral {
    if (peripheral.state == CBPeripheralStateDisconnected || peripheral.state == CBPeripheralStateDisconnecting) {
        NSLog(@"开始连接到设备, 设备的状态: %zd", peripheral.state);
        NSDictionary *options = @{CBConnectPeripheralOptionNotifyOnDisconnectionKey: @TRUE};
        [self.manager connectPeripheral:peripheral options:options];
    }
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (self.manager.state) {
        case CBCentralManagerStatePoweredOff:
        {
            NSLog(@"APP的蓝牙设置处于关闭状态");
            [self stopScanning];
            break;
        }
        case CBCentralManagerStatePoweredOn:
            NSLog(@"APP的蓝牙设置处于打开状态");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"APP的蓝牙设置处于重置状态");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"APP的蓝牙设置处于未授权状态");
            break;
        case CBCentralManagerStateUnknown:
            NSLog(@"APP的蓝牙设置处于未知状态");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"本设备不支持蓝牙功能");
            break;
        default:
            NSLog(@"未知状态");
            break;
    }
    if (self.startCompletion) {
        self.startCompletion(self, (CBCentralManagerState)self.manager.state);
    }
}

- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
//    if ([peripheral.name isEqualToString:@"Lily"] && ![self.knownPeripherals objectForKey:peripheral.identifier.UUIDString]) {
    if (![self.knownPeripherals objectForKey:peripheral.identifier.UUIDString]) {
        [self.knownPeripherals setValue:peripheral forKey:peripheral.identifier.UUIDString];
        NSLog(@"发现新设备: %@", peripheral);
//#warning 连接到测试设备
//        if ([peripheral.identifier.UUIDString isEqualToString:@"9D066131-4DB7-CF19-C0E2-96BEC4FEE956"]) {
//            NSLog(@"连接到设备, %@", peripheral.name);
//            [self connectToPeripheral:peripheral];
//        }
    }
    else {
        //        NSLog(@"发现旧设备: %@", peripheral);
    }
//    if (self.discoverDeviceCompletion) {
//        self.discoverDeviceCompletion(self, self.knownPeripherals);
//    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"连接设备成功: %@", peripheral);
    if (self.connectDeviceCompletion) {
        self.connectDeviceCompletion(self, peripheral, nil);
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    NSLog(@"连接设备失败: %@, error = %@", peripheral, error);
    if (self.connectDeviceCompletion) {
        self.connectDeviceCompletion(self, peripheral, error);
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"断开与设备连接结果: peripheral = %@, error = %@", peripheral, error);
    if (self.disConnectDeviceCompletion) {
        self.disConnectDeviceCompletion(self, peripheral, error);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:DeviceDisconnectNotification object:peripheral];
}

//#pragma mark - List
//- (BOOL)containPeripheral:(CBPeripheral *)peripheral inDeviceList:(NSArray <DLDevice *>*)deviceList {
//    __block BOOL exist = NO;
//    [deviceList enumerateObjectsUsingBlock:^(DLDevice * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        if ([obj isKindOfClass:[DLDevice class]]) {
//            if (obj.peripheral && [obj.peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
//                exist = YES;
//                *stop = YES;
//            }
//        }
//    }];
//    return exist;
//}
//
//- (DLDevice *)getDeviceFromDeviceList:(NSArray<DLDevice *> *)deviceList peripheral:(CBPeripheral *)peripheral {
//    __block DLDevice *device = nil;
//    [deviceList enumerateObjectsUsingBlock:^(DLDevice * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        if ([obj isKindOfClass:[DLDevice class]]) {
//            if (obj.peripheral && [obj.peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
//                device = obj;
//                *stop = YES;
//            }
//        }
//    }];
//    return device;
//}

//- (void)removeDeviceFromDeviceList:(NSMutableArray<DLDevice *> *)deviceList peripheral:(CBPeripheral *)peripheral {
//    DLDevice *device = [self getDeviceFromDeviceList:deviceList peripheral:peripheral];
//    if (device) {
//        [deviceList removeObject:device];
//    }
//}

#pragma mark - Properity
- (NSMutableDictionary<NSString *,CBPeripheral *> *)knownPeripherals {
    if (!_knownPeripherals) {
        _knownPeripherals = [NSMutableDictionary dictionary];
    }
    return _knownPeripherals;
}

- (NSMutableDictionary<NSString *,CBPeripheral *> *)connectedPeripherals {
    if (!_connectedPeripherals) {
        _connectedPeripherals = [NSMutableDictionary dictionary];
    }
    return _connectedPeripherals;
}
@end
