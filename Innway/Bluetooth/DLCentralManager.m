//
//  DLBluetoothDeviceManager.m
//  Bluetooth
//
//  Created by danly on 2018/8/12.
//  Copyright © 2018年 date. All rights reserved.
//

#import "DLCentralManager.h"
#import "DLDevice.h"
#import "DLUUIDTool.h"
#import <UIKit/UIKit.h>

static DLCentralManager *instance = nil;

@interface DLCentralManager()<CBCentralManagerDelegate> {
    NSMutableDictionary *_knownPeripherals;
    NSTimer *_scanTimer;
    int _time;
}

//- (void)startScanDidDiscoverDeviceEvent:(DidDiscoverDeviceEvent)discoverEvent didEndDiscoverDeviceEvent:(DidEndDiscoverDeviceEvent)endDiscoverEvent

@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) CentralManagerEvent startCompletion;
@property (nonatomic, strong) DidDiscoverDeviceEvent discoverEvent;
@property (nonatomic, strong) DidEndDiscoverDeviceEvent endDiscoverEvent;
@property (nonatomic, strong) DidConnectToDeviceEvent connectDeviceCompletion;
@property (nonatomic, strong) DidDisConnectToDeviceEvent disConnectDeviceCompletion;

@end

@implementation DLCentralManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
//        instance->_knownPeripherals = [NSMutableDictionary dictionary];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _knownPeripherals = [NSMutableDictionary dictionary];
        _scanTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(run) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_scanTimer forMode:NSRunLoopCommonModes];
        
    }
    return self;
}

- (void)dealloc {
    [_scanTimer invalidate];
    _scanTimer = nil;
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

- (void)startScanDidDiscoverDeviceEvent:(DidDiscoverDeviceEvent)discoverEvent didEndDiscoverDeviceEvent:(DidEndDiscoverDeviceEvent)endDiscoverEvent {
    [_scanTimer setFireDate:[NSDate distantFuture]];
    NSLog(@"开启设备发现功能");
    // 只删除断开连接的设备
    NSMutableArray *disconnectKeys = [NSMutableArray array];
    for (NSString *identify in _knownPeripherals.allKeys) {
        CBPeripheral *peripheral = _knownPeripherals[identify];
        if (peripheral.state == CBPeripheralStateDisconnected) {
            [disconnectKeys addObject:identify];
        }
    }
    for (NSString *identify in disconnectKeys) {
        [_knownPeripherals removeObjectForKey:identify];
    }
    // 开始扫描
    [self startScaning];
    _time = 0;
    [_scanTimer setFireDate:[NSDate distantPast]];
    self.discoverEvent = discoverEvent;
    self.endDiscoverEvent = endDiscoverEvent;
}

- (void)stopScanning {
    NSLog(@"关闭设备发现功能");
    [self.manager stopScan];
    if (self.endDiscoverEvent) {
        self.endDiscoverEvent(self, self.knownPeripherals);
    }
}


- (void)run {
    NSLog(@"定时器计时:_time = %d", _time);
    _time++;
    if (_time >= 10) {
        [_scanTimer setFireDate:[NSDate distantFuture]];
        [self stopScanning];
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
        NSDictionary *options = @{CBConnectPeripheralOptionNotifyOnNotificationKey: @TRUE};
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
            [self startScaning];
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
#warning 测试代码
    NSString *mac = [self getDeviceMac:advertisementData];
    if (mac.length == 0) {
        mac = peripheral.identifier.UUIDString;
    }
    if (![_knownPeripherals objectForKey:mac]) {
        [_knownPeripherals setValue:peripheral forKey:mac];
        if (self.discoverEvent) {
            self.discoverEvent(self, peripheral, mac);
        }
    }
    
// 有效代码
//    if ([self effectivePeripheral:advertisementData]) {
//        NSString *mac = [self getDeviceMac:advertisementData];
//        NSLog(@"发现新设备: %@, mac = %@", peripheral, mac);
//        if (![_knownPeripherals objectForKey:mac]) {
//            [_knownPeripherals setValue:peripheral forKey:mac];
//            if (self.discoverEvent) {
//                self.discoverEvent(self, peripheral, mac);
//            }
//        }
//    }
//    else {
////            NSLog(@"发现旧设备: %@", peripheral);
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
    return [_knownPeripherals copy];
}

//- (NSMutableDictionary<NSString *,CBPeripheral *> *)connectedPeripherals {
//    if (!_connectedPeripherals) {
//        _connectedPeripherals = [NSMutableDictionary dictionary];
//    }
//    return _connectedPeripherals;
//}


#pragma mark - Tool
- (NSString *)getDeviceMac:(NSDictionary *)advertisementData {
    if (advertisementData.count && [advertisementData isKindOfClass:[NSDictionary class]]) {
        NSDictionary *kCBAdvDataServiceData = advertisementData[@"kCBAdvDataServiceData"];
        if (kCBAdvDataServiceData) {
            CBUUID *macUUID = [DLUUIDTool CBUUIDFromInt:DLDeviceMAC];
            NSData *data = kCBAdvDataServiceData[macUUID];
            if (data) {
                NSString *tempStr = [data.description stringByReplacingOccurrencesOfString:@" " withString:@""];
                NSMutableString *mac = [NSMutableString stringWithString:[tempStr substringWithRange:NSMakeRange(1, 2)]];
                [mac appendString:@":"];
                [mac appendString:[tempStr substringWithRange:NSMakeRange(3, 2)]];
                [mac appendString:@":"];
                [mac appendString:[tempStr substringWithRange:NSMakeRange(5, 2)]];
                [mac appendString:@":"];
                [mac appendString:[tempStr substringWithRange:NSMakeRange(7, 2)]];
                [mac appendString:@":"];
                [mac appendString:[tempStr substringWithRange:NSMakeRange(9, 2)]];
                [mac appendString:@":"];
                [mac appendString:[tempStr substringWithRange:NSMakeRange(11, 2)]];
                return mac;
            }
        }
    }
    return nil;
}

-(BOOL)effectivePeripheral:(NSDictionary *)advertisementData {
    if (advertisementData.count && [advertisementData isKindOfClass:[NSDictionary class]]) {
        NSArray *kCBAdvDataServiceUUIDs = advertisementData[@"kCBAdvDataServiceUUIDs"];
        if (kCBAdvDataServiceUUIDs.count > 0) {
            for (CBUUID *uuid in kCBAdvDataServiceUUIDs) {
                if ([uuid.UUIDString isEqualToString:@"E001"]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}
@end
