//
//  DLPeripheral.m
//  Bluetooth
//
//  Created by danly on 2018/8/18.
//  Copyright © 2018年 date. All rights reserved.
//

#import "DLDevice.h"
#import "DLUUIDTool.h"
#import "DLCentralManager.h"
#import "InCommon.h"

#define offlineRSSI @(-120)
// 设备默认位置:22.55694872036483,114.11126873029583

@interface DLDevice() {
    NSNumber *_rssi;
    NSTimer *_readRSSITimer;
    int _time;
    BOOL _disConnect; // 标识用户主动断开了设备连接，不做重连
}

// 保存设置的值，等ack回来之后更新本地数据
@property (nonatomic, assign) BOOL disconnectAlert;
@property (nonatomic, assign) BOOL reconnectAlert;
@property (nonatomic, assign) NSInteger alertMusic;
@property (nonatomic, strong) NSMutableDictionary *data;
@end

@implementation DLDevice

+ (instancetype)device:(CBPeripheral *)peripheral {
    DLDevice *device = [[DLDevice alloc] init];
    device.peripheral = peripheral;
    // 增加断开连接通知
    [[NSNotificationCenter defaultCenter] addObserver:device selector:@selector(reconnectDevice:) name:DeviceDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:device selector:@selector(bluetoothPoweredOff) name:BluetoothPoweredOffNotification object:nil];
    return device;
}

- (instancetype)init {
    if (self = [super init]) {
        // 设置默认位置 22.55694872036483,114.11126873029583
        _coordinate = CLLocationCoordinate2DMake(22.55694872036483, 114.11126873029583);
        
        // 初始化1秒扫描一次RSSI的定时器
        _readRSSITimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(readRSSI) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_readRSSITimer forMode:NSRunLoopCommonModes];
        
        _disConnect = NO;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BluetoothPoweredOffNotification object:nil];
    //移除扫描RSSI定时器
    [_readRSSITimer invalidate];
    _readRSSITimer = nil;
}

- (void)reconnectDevice:(NSNotification *)notification {
    CBPeripheral *peripheral = notification.object;
    if ([peripheral.identifier.UUIDString isEqualToString:self. peripheral.identifier.UUIDString]) {
        self.online = NO;
        if (!_disConnect) { //被动的掉线，做重连
            NSLog(@"设备连接被断开，去重连设备, mac = %@", self.mac);
            [self connectToDevice:^(DLDevice *device, NSError *error) {
                if (error) {
                    NSLog(@"mac: %@, 设备重连失败", self.mac);
                }
                else {
                    NSLog(@"mac: %@, 设备重连成功", self.mac);
                }
            }];
        }
    }
}

- (void)discoverServices {
    if (_peripheral) {
        NSLog(@"去获取设备服务:%@", self.mac);
        CBUUID *serviceUUID = [DLUUIDTool CBUUIDFromInt:DLServiceUUID];
        [_peripheral discoverServices:@[serviceUUID]];
    }
    else {
        NSLog(@"无法去获取设备服务:%@, 外设不存在", self.mac);
    }
}

- (void)peripheral:(CBPeripheral *)_peripheral didDiscoverServices:(NSError *)error {
    NSArray *services = [_peripheral services];
    CBUUID *serverUUID = [DLUUIDTool CBUUIDFromInt:DLServiceUUID];
    for (CBService *service in services) {
        if ([service.UUID.UUIDString isEqualToString:serverUUID.UUIDString]) {
//            NSLog(@"发现服务0xE001");
            CBUUID *ntfUUID = [DLUUIDTool CBUUIDFromInt:DLNTFCharacteristicUUID];
            CBUUID *writeUUID = [DLUUIDTool CBUUIDFromInt:DLWriteCharacteristicUUID];
            [self.peripheral discoverCharacteristics:@[ntfUUID, writeUUID] forService:service];
        }
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    CBUUID *ntfUUID = [DLUUIDTool CBUUIDFromInt:DLNTFCharacteristicUUID];
    CBUUID *writeUUID = [DLUUIDTool CBUUIDFromInt:DLWriteCharacteristicUUID];
    NSArray *characteristics = [service characteristics];
    for (CBCharacteristic *characteristic in characteristics) {
        if ([characteristic.UUID.UUIDString isEqualToString:writeUUID.UUIDString]) {
//            NSLog(@"发现E002写角色，开始激活设备，并获取设备信息");
            [self activeDevice];
            [self getDeviceInfo];
        }
        if ([characteristic.UUID.UUIDString isEqualToString:ntfUUID.UUIDString]) {
//            NSLog(@"发现E003, 打开监听来自设备通知的功能");
            [self notification:DLServiceUUID characteristicUUID:DLNTFCharacteristicUUID p:self.peripheral on:YES];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    if (peripheral == self.peripheral && !error) {
        self.rssi = RSSI;
    }
}

#pragma mark - 写数据快捷接口
- (void)activeDevice {
    char active[1] = {0x01};
    [self write:[NSData dataWithBytes:active length:strlen(active)]];
}

- (void)getDeviceInfo {
    NSLog(@"mac = %@, 去获取设备硬件数据", self.mac);
    char getDeviceInfo[4] = {0xEE, 0x01, 0x00, 0x00};
    [self write:[NSData dataWithBytes:getDeviceInfo length:strlen(getDeviceInfo)]];
}

- (void)searchDevice {
    char search[4] = {0xEE, 0x03, 0x00, 0x00};
    [self write:[NSData dataWithBytes:search length:strlen(search)]];
}

- (void)setDisconnectAlert:(BOOL)disconnectAlert reconnectAlert:(BOOL)reconnectAlert {
    self.disconnectAlert = disconnectAlert;
    self.reconnectAlert = reconnectAlert;
    int disconnect = disconnectAlert? 0x01 : 0x00;
    int reconnect = reconnectAlert? 0x01: 0x00;
    char command[6] = {0xEE, 0x07, 0x02, disconnect, reconnect, 0x00};
    [self write:[NSData dataWithBytes:command length:strlen(command)]];
}

//警报音编码，可选 01，02，03
- (void)selecteDiconnectAlertMusic:(NSInteger)alertMusic {
    self.alertMusic = alertMusic;
    int alert;
    switch (alertMusic) {
        case 1:
            alert = 0x01;
            break;
        case 2:
            alert = 0x02;
            break;
        case 3:
            alert = 0x03;
            break;
        default:
            alert = 0x01;
            break;
    }
    char command[6] = {0xEE, 0x09, 0x01, alert, 0x00};
    [self write:[NSData dataWithBytes:command length:strlen(command)]];
}

- (void)parseData:(NSData *)data {
    NSString *dataStr = data.description;
    dataStr =  [dataStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *cmd = [dataStr substringWithRange:NSMakeRange(3, 2)];
//    NSLog(@"cmd = %@", cmd);
    NSString *length = [dataStr substringWithRange:NSMakeRange(5, 2)];
    NSString *payload = [dataStr substringWithRange:NSMakeRange(7, length.integerValue * 2)];
    //校验和
//    NSString *cs = [dataStr substringWithRange:NSMakeRange(7+length.integerValue*2, 2)];
//    NSLog(@"cmd = %@, length = %@, payload = %@, cs = %@", cmd, length, payload, cs);
    if ([cmd isEqualToString:@"02"]) {
        if (payload.length != 10) {
            return;
        }
        //获取设备信息的回调
        NSString *electric = [payload substringWithRange:NSMakeRange(0, 2)];
        NSString *chargingState = [payload substringWithRange:NSMakeRange(2, 2)];
        NSString *disconnectAlert = [payload substringWithRange:NSMakeRange(4, 2)];
        NSString *reconnectAlert = [payload substringWithRange:NSMakeRange(6, 2)];
        NSString *alertMusic = [payload substringWithRange:NSMakeRange(8, 2)];
        [self.data setValue:@(electric.integerValue) forKey:ElectricKey];
        [self.data setValue:@(chargingState.boolValue) forKey:ChargingStateKey];
        [self.data setValue:@(disconnectAlert.boolValue) forKey:DisconnectAlertKey];
        [self.data setValue:@(reconnectAlert.boolValue) forKey:ReconnectAlertKey];
        [self.data setValue:@(alertMusic.integerValue) forKey:AlertMusicKey];
//        NSLog(@"获取到的设备数据: %@", self.data.description);
    }
    else if ([cmd isEqualToString:@"04"]) {
        if (payload.length != 2) {
            return;
        }
        NSString *alertStatus = [payload substringWithRange:NSMakeRange(0, 2)];
        NSLog(@"alertStatus = %@", alertStatus);
        [self.data setValue:@(alertStatus.boolValue) forKey:AlertStatusKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:DeviceSearchDeviceAlertNotification object:self userInfo:@{AlertStatusKey:@(alertStatus.boolValue)}];
    }
    else if ([cmd isEqualToString:@"05"]) {
        NSLog(@"设备寻找手机，手机要发出警报");
        [[NSNotificationCenter defaultCenter] postNotificationName:DeviceSearchPhoneNotification object:self userInfo:@{@"Device":self}];
    }
    else if ([cmd isEqualToString:@"08"]) {
        [self.data setValue:@(self.disconnectAlert) forKey:DisconnectAlertKey];
        [self.data setValue:@(self.reconnectAlert) forKey:ReconnectAlertKey];
    }
    else if ([cmd isEqualToString:@"0a"]) {
        [self.data setValue:@(self.alertMusic) forKey:AlertMusicKey];
    }
}

#pragma mark - 写数据
- (void) write:(NSData *)data {
    if (self.peripheral && self.connected) {
        [self writeValue:DLServiceUUID characteristicUUID:DLWriteCharacteristicUUID p:self.peripheral data:data andResponseType:CBCharacteristicWriteWithoutResponse];
    }
}

- (void) writeValue:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data andResponseType:(CBCharacteristicWriteType)responseType
{
    CBUUID *su = [DLUUIDTool CBUUIDFromInt:serviceUUID];
    CBUUID *cu = [DLUUIDTool CBUUIDFromInt:characteristicUUID];
    CBService *service = [self findServiceFromUUID:su p:p];
    if (!service) {
        NSLog(@"mac:%@, 写数据查找不到服务: %s", self.mac, [self CBUUIDToString:su]);
        [self discoverServices]; // 去发现服务
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
        NSLog(@"mac:%@, 写数据查找不到角色: %s", self.mac, [self CBUUIDToString:cu]);
        [self peripheral:p didDiscoverServices:nil]; // 去发现角色
        return;
    }
    [p writeValue:data forCharacteristic:characteristic type:responseType];
}

- (void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"mac:%@, 写入的响应值: %@,  %@", self.mac, characteristic, error);
//    [self readData];
}

//- (void)readData {
//    if (self.peripheral) {
//        [self readValue:DLServiceUUID characteristicUUID:DLNTFCharacteristicUUID p:self.peripheral];
//    }
//    else {
//        NSLog(@"mac:%@, 查找不到外设，无法读数据", self.mac);
//    }
//}

-(void) readValue: (int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p {
    CBUUID *su = [DLUUIDTool CBUUIDFromInt:serviceUUID];
    CBUUID *cu = [DLUUIDTool CBUUIDFromInt:characteristicUUID];
    CBService *service = [self findServiceFromUUID:su p:p];
    if (!service) {
        NSLog(@"mac:%@, 读数据查找不到服务: %s", self.mac, [self CBUUIDToString:su]);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
        NSLog(@"mac:%@, 读数据查找不到角色: %s", self.mac, [self CBUUIDToString:cu]);
        return;
    }
    [p readValueForCharacteristic:characteristic];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"mac:%@, 接收读响应数据, characteristic = %@, error = %@", self.mac, characteristic.value, error);
    [self parseData:characteristic.value];
    if (self.delegate) {
        [self.delegate device:self didUpdateData:self.lastData];
    }
}


/*!
 *  @method notification:
 *
 *  @param serviceUUID Service UUID to read from (e.g. 0x2400)
 *  @param characteristicUUID Characteristic UUID to read from (e.g. 0x2401)
 *  @param p CBPeripheral to read from
 *
 *  @discussion Main routine for enabling and disabling notification services. It converts integers
 *  into CBUUID's used by CoreBluetooth. It then searches through the peripherals services to find a
 *  suitable service, it then checks that there is a suitable characteristic on this service.
 *  If this is found, the notfication is set.
 *
 */
- (void)notification:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on {
    CBUUID *su = [DLUUIDTool CBUUIDFromInt:serviceUUID];
    CBUUID *cu = [DLUUIDTool CBUUIDFromInt:characteristicUUID];
    CBService *service = [self findServiceFromUUID:su p:p];
    if (!service) {
        NSLog(@"mac:%@, 通知功能更查找不到服务: %s", self.mac, [self CBUUIDToString:su]);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
        NSLog(@"mac:%@,  通知功能更查找不到角色: %s", self.mac, [self CBUUIDToString:cu]);
        return;
    }
    [p setNotifyValue:on forCharacteristic:characteristic];
}

/*!
 *  @method peripheral:didUpdateNotificationStateForCharacteristic:error:
 *
 *  @param peripheral        The peripheral providing this information.
 *  @param characteristic    A <code>CBCharacteristic</code> object.
 *    @param error            If an error occurred, the cause of the failure.
 *
 *  @discussion                This method returns the result of a @link setNotifyValue:forCharacteristic: @/link call.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    NSLog(@"mac:%@, 接收来自设备的通知, characteristic = %@, error = %@", self.mac, characteristic, error);
    [self parseData:characteristic.value];
}

#pragma mark - 连接与断开连接
- (void)connectToDevice:(void (^)(DLDevice *device, NSError *error))completion {
    _disConnect = NO; // 重新设置断开连接的标识
    if (!self.peripheral) {
        NSError *error = [NSError errorWithDomain:NSStringFromClass([DLCentralManager class]) code:-2 userInfo:@{NSLocalizedDescriptionKey: @"与设备建立连接失败"}];
        if (completion) {
            completion(self, error);
        }
        return;
    }
    if (self.peripheral.state == CBPeripheralStateDisconnected || self.peripheral.state == CBPeripheralStateDisconnecting) {
        NSLog(@"开始去连接设备:%@", self.mac);
        [[DLCentralManager sharedInstance] connectToDevice:self.peripheral completion:^(DLCentralManager *manager, CBPeripheral *peripheral, NSError *error) {
            if (!error) {
//                [common sendLocalNotification:[NSString stringWithFormat:@"%@ 已建立连接", self.deviceName]];
                NSLog(@"连接设备成功:%@", self.mac);
                // 连接成功，去获取设备服务
                self.online = YES;  //设置在线
                peripheral.delegate = self;
                [self discoverServices];
            }
            if (completion) {
                completion(self, error);
            }
        }];
    }
    else {
        if (completion) {
            completion(self, nil);
        }
    }
}

- (void)disConnectToDevice:(void (^)(DLDevice *device, NSError *error))completion {
    _disConnect = YES;
    if (!self.peripheral) {
        // 不存在外设，当成断开设备连接成功
        if (completion) {
            completion(self, nil);
        }
        return;
    }
    NSLog(@"开始去断开设备连接:%@", self.mac);
    [[DLCentralManager sharedInstance] disConnectToDevice:self.peripheral completion:^(DLCentralManager *manager, CBPeripheral *peripheral, NSError *error) {
        if (completion) {
            completion(self, error);
        }
    }];
}

#pragma mark - 查找服务和角色的作用
/*
 *  @method findServiceFromUUID:
 *
 *  @param UUID CBUUID to find in service list
 *  @param p Peripheral to find service on
 *
 *  @return pointer to CBService if found, nil if not
 *
 *  @discussion findServiceFromUUID searches through the services list of a peripheral to find a
 *  service with a specific UUID
 *
 */
-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p {
    for(int i = 0; i < p.services.count; i++) {
        CBService *s = [p.services objectAtIndex:i];
        if ([self compareCBUUID:s.UUID UUID2:UUID]) return s;
    }
    return nil; //Service not found on this peripheral
}

/*
 *  @method findCharacteristicFromUUID:
 *
 *  @param UUID CBUUID to find in Characteristic list of service
 *  @param service Pointer to CBService to search for charateristics on
 *
 *  @return pointer to CBCharacteristic if found, nil if not
 *
 *  @discussion findCharacteristicFromUUID searches through the characteristic list of a given service
 *  to find a characteristic with a specific UUID
 *
 */
-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service {
    for(int i=0; i < service.characteristics.count; i++) {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([self compareCBUUID:c.UUID UUID2:UUID]) return c;
    }
    return nil; //Characteristic not found on this service
}

/*
 *  @method compareCBUUID
 *
 *  @param UUID1 UUID 1 to compare
 *  @param UUID2 UUID 2 to compare
 *
 *  @returns equal
 *
 *  @discussion compareCBUUID compares two CBUUID's to each other and returns YES if they are equal and NO if they are not
 *
 */

-(BOOL) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2 {
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1 length:16];
    [UUID2.data getBytes:b2 length:16];
    return memcmp(b1, b2, UUID1.data.length) == 0;
}

/*
 *  @method CBUUIDToString
 *
 *  @param UUID UUID to convert to string
 *
 *  @returns Pointer to a character buffer containing UUID in string representation
 *
 *  @discussion CBUUIDToString converts the data of a CBUUID class to a character pointer for easy printout using printf()
 *
 */
-(const char *) CBUUIDToString:(CBUUID *) UUID {
    return [[UUID.data description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
}



#pragma mark - Properity
- (void)setPeripheral:(CBPeripheral *)peripheral {
    if ([_peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
        // 已经赋值过的设备不需要重新设置
        return;
    }
    self.online = NO;
    [_peripheral setDelegate:nil];
    _peripheral = peripheral;
    if (peripheral) {
        [peripheral setDelegate:self];
    }
}

- (NSMutableDictionary *)data {
    if (!_data) {
        _data = [NSMutableDictionary dictionary];
        [self.data setValue:@(0) forKey:ElectricKey];
        [self.data setValue:@(0) forKey:ChargingStateKey];
        [self.data setValue:@(0) forKey:DisconnectAlertKey];
        [self.data setValue:@(0) forKey:ReconnectAlertKey];
        [self.data setValue:@(1) forKey:AlertMusicKey];
        [self.data setValue:@(0) forKey:AlertStatusKey];
    }
    return _data;
}

- (NSDictionary *)lastData {
    return [self.data copy];
}

- (NSString *)deviceName {
    if (_deviceName.length == 0) {
        _deviceName = self.peripheral.name;
    }
    if (_deviceName.length == 0 || [_deviceName isEqualToString:@"Lily"]) {
        _deviceName = @"Card";
    }
    return _deviceName;
}

- (void)setOnline:(BOOL)online {
    if (_online && !online) {
        // 从在线变为离线, 上传设备的新位置并做掉线通知
        _coordinate = [InCommon sharedInstance].currentLocation;
        [[InCommon sharedInstance] uploadDeviceLocation:self];
        if ([self.lastData boolValueForKey:DisconnectAlertKey defaultValue:NO]) {
            // 关闭的断开连接通知，则不通知
            [common sendLocalNotification:[NSString stringWithFormat:@"%@ 已断开连接", self.deviceName]];
        }
    }
    _online = online;
    if (!_online) {
        _rssi = offlineRSSI;  // 设置rssi掉线
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:DeviceOnlineChangeNotification object:@(online)];
}

- (BOOL)connected {
    if ([DLCentralManager sharedInstance].state != CBCentralManagerStatePoweredOn) {
        return NO;
    }
    if (_peripheral && (_peripheral.state == CBPeripheralStateConnected || _peripheral.state == CBPeripheralStateConnecting)) {
        return YES;
    }
    return NO;
}

- (void)setCoordinate:(NSString *)gps {
    if ([gps isKindOfClass:[NSString class]]) {
        NSArray *strs = [gps componentsSeparatedByString:@","];
        if (strs.count == 2) {
            NSString *latitude = strs[0];
            NSString *longitude = strs[1];
            _coordinate.latitude = latitude.doubleValue;
            _coordinate.longitude = longitude.doubleValue;
            NSLog(@"_coordinate.latitude = %f, _coordinate.longitude = %f", _coordinate.latitude, _coordinate.longitude);
        }
    }
}

- (NSString *)getGps{
    CLLocationCoordinate2D deviceLocation = _coordinate;
    NSString *gps = [NSString stringWithFormat:@"%f,%f", deviceLocation.latitude, deviceLocation.longitude];
    return gps;
}

- (NSNumber *)rssi {
    if (!_rssi) {
        _rssi = offlineRSSI;
    }
    return _rssi;
}

- (void)setRssi:(NSNumber *)rssi {
    _rssi = rssi;
    if (rssi.integerValue > -100 && !self.connected) {
        // 设备信号高了，要去重连设备
        NSLog(@"设备信号变强，去重新连接设备");
        [self connectToDevice:nil];
    }
    if (rssi.intValue == offlineRSSI.intValue) {
        // 设置设备离线
        self.online = NO;
    }
    // RSSI改变要发出通知
    [[NSNotificationCenter defaultCenter] postNotificationName:DeviceRSSIChangeNotification object:self];
}

- (void)readRSSI {
    if (self.connected) {
//        NSLog(@"定时读取设备的RSSI值: %@", self.mac);
        [self.peripheral readRSSI];
    }
}

- (void)bluetoothPoweredOff {
    self.online = NO;
}

@end
