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

@interface DLDevice()
@property (nonatomic, strong) NSMutableDictionary *data;

// 保存设置的值，等ack回来之后更新本地数据
@property (nonatomic, assign) BOOL disconnectAlert;
@property (nonatomic, assign) BOOL reconnectAlert;
@property (nonatomic, assign) NSInteger alertMusic;
@end

@implementation DLDevice

+ (instancetype)device:(CBPeripheral *)peripheral {
    DLDevice *device = [[DLDevice alloc] init];
    device.peripheral = peripheral;
    NSLog(@"设置peripheral--创建设备mac, peripheral = %@", peripheral);
    [[NSNotificationCenter defaultCenter] addObserver:device selector:@selector(reconnectDevice:) name:DeviceDisconnectNotification object:nil];
    return device;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceDisconnectNotification object:nil];
}

- (void)reconnectDevice:(NSNotification *)notification {
    return;
    CBPeripheral *peripheral = notification.object;
    if ([peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
        [[DLCentralManager sharedInstance] connectToDevice:peripheral completion:^(DLCentralManager *manager, CBPeripheral *peripheral, NSError *error) {
            if (error) {
                NSLog(@"重连失败");
                self.online = false;
            }
            else {
                NSLog(@"重连成功");
                [self discoverServices];
            }
        }];
    }
}

- (BOOL)discoverServices {
    if (_peripheral) {
        self.online = YES;  //设置在线
        [_peripheral setDelegate:self];
        CBUUID *serviceUUID = [DLUUIDTool CBUUIDFromInt:DLServiceUUID];
        [_peripheral discoverServices:@[serviceUUID]];
        return YES;
    }
    return NO;
}

- (void)peripheral:(CBPeripheral *)_peripheral didDiscoverServices:(NSError *)error {
    NSArray *services = [_peripheral services];
    for (CBService *service in services) {
        NSLog(@"UUID = %@", [service UUID]);
        CBUUID *uuid1 = [DLUUIDTool CBUUIDFromInt:DLNTFCharacteristicUUID];
        CBUUID *uuid2 = [DLUUIDTool CBUUIDFromInt:DLWriteCharacteristicUUID];
        [self.peripheral discoverCharacteristics:@[uuid1, uuid2] forService:service];
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"Characteristics for service %@ (%@)", [service UUID], service);
    NSArray *characteristics = [service characteristics];
    for (CBCharacteristic *characteristic in characteristics) {
        NSLog(@" -- Characteristic %@ (%@)", [characteristic UUID], characteristic);
        [self notification:DLServiceUUID characteristicUUID:DLNTFCharacteristicUUID p:self.peripheral on:YES];
        [self activeDevice];  //激活设备
    }
}

#pragma mark - 写数据快捷接口
- (void)activeDevice {
    char active[1] = {0x01};
    [self write:[NSData dataWithBytes:active length:strlen(active)]];
}

- (void)getDeviceInfo {
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
    NSString *cs = [dataStr substringWithRange:NSMakeRange(7+length.integerValue*2, 2)];
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
    }
    else if ([cmd isEqualToString:@"06"]) {
        NSLog(@"设备寻找手机，手机要发出警报");
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
    if (self.peripheral) {
        [self writeValue:DLServiceUUID characteristicUUID:DLWriteCharacteristicUUID p:self.peripheral data:data andResponseType:CBCharacteristicWriteWithoutResponse];
    }
    else {
        NSLog(@"查找不到外设，无法写入数据");
    }
}

- (void) writeValue:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data andResponseType:(CBCharacteristicWriteType)responseType
{
    CBUUID *su = [DLUUIDTool CBUUIDFromInt:serviceUUID];
    CBUUID *cu = [DLUUIDTool CBUUIDFromInt:characteristicUUID];
    CBService *service = [self findServiceFromUUID:su p:p];
    if (!service) {
        NSLog(@"写数据查找不到服务: %s", [self CBUUIDToString:su]);
        [self discoverServices];
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
        NSLog(@"写数据查找不到角色: %s", [self CBUUIDToString:cu]);
        [self peripheral:p didDiscoverServices:nil];
        return;
    }
    [p writeValue:data forCharacteristic:characteristic type:responseType];
}

- (void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"写入的响应值: %@,  %@", characteristic, error);
//    [self readData];
}

- (void)readData {
    if (self.peripheral) {
        [self readValue:DLServiceUUID characteristicUUID:DLNTFCharacteristicUUID p:self.peripheral];
    }
    else {
        NSLog(@"查找不到外设，无法读数据");
    }
}

-(void) readValue: (int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p {
    CBUUID *su = [DLUUIDTool CBUUIDFromInt:serviceUUID];
    CBUUID *cu = [DLUUIDTool CBUUIDFromInt:characteristicUUID];
    CBService *service = [self findServiceFromUUID:su p:p];
    if (!service) {
        NSLog(@"读数据查找不到服务: %s", [self CBUUIDToString:su]);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
        NSLog(@"读数据查找不到角色: %s", [self CBUUIDToString:cu]);
        return;
    }
    [p readValueForCharacteristic:characteristic];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"接收读响应数据, characteristic = %@, error = %@", characteristic.value, error);
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
-(void) notification:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on {
    CBUUID *su = [DLUUIDTool CBUUIDFromInt:serviceUUID];
    CBUUID *cu = [DLUUIDTool CBUUIDFromInt:characteristicUUID];
    CBService *service = [self findServiceFromUUID:su p:p];
    if (!service) {
        NSLog(@"通知功能更查找不到服务: %s", [self CBUUIDToString:su]);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
        NSLog(@"通知功能更查找不到角色: %s", [self CBUUIDToString:cu]);
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
    NSLog(@"接收来自设备的通知, characteristic = %@, error = %@", characteristic, error);
    [self parseData:characteristic.value];
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
    NSLog(@"设置外设: %@", peripheral);
    if ([_peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
        return;
    }
    self.online = false;
    if (_peripheral) {
        // 外设地址发生变化
        NSLog(@"执行方法:%s, 外设地址放生变化: 旧的外设:%@, 新的外设:%@", __func__, peripheral, _peripheral);
        [_peripheral setDelegate:nil];
        _peripheral = peripheral;
        [peripheral setDelegate:self];
        [[DLCentralManager sharedInstance] connectToDevice:peripheral completion:^(DLCentralManager *manager, CBPeripheral *connectPeripheral, NSError *error) {
            if (peripheral == connectPeripheral && !error){
                //连接成功
                [self discoverServices];
            }
        }];
    }
    else {
        // 第一次赋值外设
        _peripheral = peripheral;
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
    return _deviceName;
}

- (void)setOnline:(BOOL)online {
    _online = online;
}

- (BOOL)connected {
    if (_peripheral && (_peripheral.state == CBPeripheralStateConnected || _peripheral.state == CBPeripheralStateConnecting)) {
        return YES;
    }
    return NO;
}

@end
