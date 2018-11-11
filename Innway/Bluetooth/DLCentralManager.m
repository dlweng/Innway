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
#import "DLCloudDeviceManager.h"

static DLCentralManager *instance = nil;

@implementation DLKnowDevice
@end

@interface DLCentralManager()<CBCentralManagerDelegate> {
    NSMutableDictionary *_knownPeripherals;
    // 计算发现时间的延时器
    NSTimer *_scanTimer;
    int _time;
    int _timeout;
    
    // 定时去调用一次发现新设备的定时器
    NSTimer *_repeatScanTimer;
}

@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) CentralManagerEvent startCompletion;
@property (nonatomic, strong) DidDiscoverDeviceEvent discoverEvent;
@property (nonatomic, strong) DidEndDiscoverDeviceEvent endDiscoverEvent;
//@property (nonatomic, strong) DidConnectToDeviceEvent connectDeviceCompletion;
//@property (nonatomic, strong) DidDisConnectToDeviceEvent disConnectDeviceCompletion;
@property (nonatomic, strong) NSMutableDictionary *connectDeviceEventDict;
@property (nonatomic, strong) NSMutableDictionary *disConnectDeviceEventDict;

@end

@implementation DLCentralManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        // 创建定时器，初始化发现列表
        _knownPeripherals = [NSMutableDictionary dictionary];
        _scanTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(run) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_scanTimer forMode:NSRunLoopCommonModes];
        _repeatScanTimer = [NSTimer timerWithTimeInterval:120 target:self selector:@selector(repeatScanNewDevice) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_repeatScanTimer forMode:NSRunLoopCommonModes];
        
        _connectDeviceEventDict = [NSMutableDictionary dictionary];
        _disConnectDeviceEventDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    // 销毁定时器
    [_scanTimer invalidate];
    _scanTimer = nil;
    [_repeatScanTimer invalidate];
    _repeatScanTimer = nil;
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

- (void)startScanDeviceWithTimeout:(int)timeout discoverEvent:(DidDiscoverDeviceEvent)discoverEvent didEndDiscoverDeviceEvent:(DidEndDiscoverDeviceEvent)endDiscoverEvent {
        NSLog(@"开启设备发现功能");
    
    // 重置扫描设备参数
    _timeout = timeout;
    [_scanTimer setFireDate:[NSDate distantFuture]]; // 关闭定时器

    // 只删除断开连接的设备
    NSMutableArray *disconnectKeys = [NSMutableArray array];
    for (NSString *mac in _knownPeripherals.allKeys) {
        DLKnowDevice *knowDevice = _knownPeripherals[mac];
        if (knowDevice.peripheral.state == CBPeripheralStateDisconnected) {
            [disconnectKeys addObject:mac];
        }
    }
    for (NSString *mac in disconnectKeys) {
        [_knownPeripherals removeObjectForKey:mac];
    }
    
    // 开始扫描
    [self startScaning];
    // 开始扫描计时
    _time = 0;
    [_scanTimer setFireDate:[NSDate distantPast]];
    self.discoverEvent = discoverEvent;
    self.endDiscoverEvent = endDiscoverEvent;
}

- (void)stopScanning {
    NSLog(@"关闭设备发现功能, endDiscoverEvent = %@", self.endDiscoverEvent);
    [self.manager stopScan];
    // 更新一下云端列表
    if (self.endDiscoverEvent) {
        self.endDiscoverEvent(self, self.knownPeripherals);
    }
}


- (void)run {
//    NSLog(@"定时器计时:_time = %d", _time);
    _time++;
    if (_time >= _timeout) {
        // 关闭定时器，停止扫描
        [_scanTimer setFireDate:[NSDate distantFuture]];
        [self stopScanning];
    }
}

- (void)repeatScanNewDevice {
//    NSLog(@"2分钟扫描一次设备");
    // 每2分钟扫描20秒钟设备
    [self startScanDeviceWithTimeout:10 discoverEvent:nil didEndDiscoverDeviceEvent:nil];
}

- (void)connectToDevice: (CBPeripheral *)peripheral completion:(DidConnectToDeviceEvent)completion {
    NSDictionary *options = @{CBConnectPeripheralOptionNotifyOnDisconnectionKey: @NO, CBConnectPeripheralOptionNotifyOnConnectionKey: @NO,CBConnectPeripheralOptionNotifyOnNotificationKey: @NO};
    [self.manager connectPeripheral:peripheral options:options];
    
    if (completion) {
        [self.connectDeviceEventDict setValue:completion forKey:peripheral.identifier.UUIDString];
    }
}

- (void)disConnectToDevice: (CBPeripheral *)peripheral completion:(DidDisConnectToDeviceEvent)completion {
    [self.manager cancelPeripheralConnection:peripheral];
    if (self.manager.state != CBCentralManagerStatePoweredOn) {
        if (completion) {
            completion(self, peripheral, nil);
        }
        return;
    }
    if (completion) {
        [self.disConnectDeviceEventDict setValue:completion forKey:peripheral.identifier.UUIDString];
    }
}

#pragma mark - 内部工具方法
- (void)startScaning {
    [self.manager scanForPeripheralsWithServices:nil options:nil];
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (self.manager.state) {
        case CBCentralManagerStatePoweredOff:
        {
            NSLog(@"APP的蓝牙设置处于关闭状态");
            [_repeatScanTimer setFireDate:[NSDate distantFuture]];
            [self stopScanning];
            [[NSNotificationCenter defaultCenter] postNotificationName:BluetoothPoweredOffNotification object:nil];
            break;
        }
        case CBCentralManagerStatePoweredOn:
        {
            [_repeatScanTimer setFireDate:[NSDate distantPast]];
            NSLog(@"APP的蓝牙设置处于打开状态");
            break;
        }
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
//    NSLog(@"发现新设备： %@, advertisementData = %@", peripheral, advertisementData);
// 有效代码
// 广播数据案例
//    advertisementData = {
//        kCBAdvDataIsConnectable = 1;
//        kCBAdvDataLocalName = Lily;  // 设备名称
//        kCBAdvDataServiceData =     {
//            D888 = <00000000 0014>;   // D888表示设备mac地址
//        };
//        kCBAdvDataServiceUUIDs =     (
//                                      E001 // E001表示是innway的设备
//                                      );
//    }
    if ([self effectivePeripheral:advertisementData]) {
        NSString *mac = [self getDeviceMac:advertisementData];
        if (mac.length > 0) {
            DLKnowDevice *knowDevice = [_knownPeripherals objectForKey:mac];
            if (!knowDevice) {
                // 发现列表不存在该设备，需要添加
                NSLog(@"发现新设备: %@, advertisementData = %@", mac, advertisementData);
                knowDevice = [[DLKnowDevice alloc] init];
                knowDevice.peripheral = peripheral;
                [_knownPeripherals setValue:knowDevice forKey:mac];
            }
            
            //更新rssi
            knowDevice.rssi = RSSI;
            if(![DLCloudDeviceManager sharedInstance].cloudDeviceList[mac]) {
                // 设备不存在云端列表，且设备类型与客户查找的类型相同，才回调
                BOOL callback = NO;
                InDeviceType findDeviceType = [common getDeviceType:peripheral];
                if (common.deviceType == findDeviceType || (common.deviceType == InDeviceAll && (findDeviceType == InDeviceTag || findDeviceType == InDeviceChip || findDeviceType == InDeviceCard))) {
                    callback = YES;
                }
                if (callback && self.discoverEvent) {
                    self.discoverEvent(self, peripheral, mac);
                }
            }
            else {
                // 设备存在云端列表，更新
                [[DLCloudDeviceManager sharedInstance] updateCloudList];
            }
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
//    NSLog(@"连接设备成功: %@", peripheral);
    //    if (self.connectDeviceCompletion) {
    //        self.connectDeviceCompletion(self, peripheral, nil);
    //    }
    
    DidConnectToDeviceEvent event = [self.connectDeviceEventDict objectForKey:peripheral.identifier.UUIDString];
    if (event) {
        event(self, peripheral, nil);
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
//    NSLog(@"连接设备失败: %@, error = %@", peripheral, error);
//    if (self.connectDeviceCompletion) {
//        self.connectDeviceCompletion(self, peripheral, error);
//    }
    DidConnectToDeviceEvent event = [self.connectDeviceEventDict objectForKey:peripheral.identifier.UUIDString];
    if (event) {
        event(self, peripheral, nil);
        [self.connectDeviceEventDict removeObjectForKey:peripheral.identifier.UUIDString];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    // 被动断开连接时，error才不为Nil，此时才需要去做重连
    // 发出断开连接通知
    [[NSNotificationCenter defaultCenter] postNotificationName:DeviceDisconnectNotification object:peripheral];
//    if (self.disConnectDeviceCompletion) {
//        self.disConnectDeviceCompletion(self, peripheral, error);
//    }
    
    DidDisConnectToDeviceEvent event = [self.disConnectDeviceEventDict objectForKey:peripheral.identifier.UUIDString];
    if (event) {
        event(self, peripheral, error);
        [self.disConnectDeviceEventDict removeObjectForKey:peripheral.identifier.UUIDString];
    }
}

#pragma mark - Tool
- (NSString *)getDeviceMac:(NSDictionary *)advertisementData {
    if (advertisementData.count && [advertisementData isKindOfClass:[NSDictionary class]]) {
        NSDictionary *kCBAdvDataServiceData = advertisementData[@"kCBAdvDataServiceData"];
        if (kCBAdvDataServiceData) {
            CBUUID *macUUID = [DLUUIDTool CBUUIDFromInt:DLDeviceMAC];
            NSData *data = kCBAdvDataServiceData[macUUID];
            if (!data) {
                // 适配旧的测试设备
                macUUID = [DLUUIDTool CBUUIDFromInt:0xD006];
                data = kCBAdvDataServiceData[macUUID];
            }
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

#pragma mark - Properity
- (NSMutableDictionary<NSString *, DLKnowDevice*> *)knownPeripherals {
    return [_knownPeripherals copy];
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

//- (NSMutableDictionary<NSString *,CBPeripheral *> *)connectedPeripherals {
//    if (!_connectedPeripherals) {
//        _connectedPeripherals = [NSMutableDictionary dictionary];
//    }
//    return _connectedPeripherals;
//}

- (CBCentralManagerState)state {
    return self.manager.state;
}

@end
