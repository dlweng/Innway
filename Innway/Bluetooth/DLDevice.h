//
//  DLPeripheral.h
//  Bluetooth
//
//  Created by danly on 2018/8/18.
//  Copyright © 2018年 date. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <MapKit/MapKit.h>
#import "InCommon.h"

#define ElectricKey @"Electric"
#define ChargingStateKey @"ChargingState"
#define DisconnectAlertKey @"DisconnectAlert"
#define ReconnectAlertKey @"ReconnectAlert"
#define AlertMusicKey @"AlertMusic"
#define AlertStatusKey @"AlertStatusKey"
#define PhoneAlertMusicKey @"PhoneAlertMusic"

#define DeviceOnlineChangeNotification @"DeviceOnlineChangeNotification"
#define DeviceSearchPhoneNotification @"DeviceSearchPhoneNotification"
#define DeviceSearchDeviceAlertNotification @"DeviceSearchDeviceAlertNotification"
#define DeviceRSSIChangeNotification  @"DeviceRSSIChangeNotification"

@class DLDevice;
typedef void (^DidUpdateValue)(DLDevice *device, NSDictionary *value, NSError *error);

@protocol DLDeviceDelegate
- (void)device:(DLDevice *)device didUpdateData:(NSDictionary *)data;
@end

// 云端设备类
@interface DLDevice : NSObject<CBPeripheralDelegate>
@property (nonatomic, weak) id<DLDeviceDelegate> delegate;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, assign) NSInteger cloudID;
@property (nonatomic, copy) NSString *mac;
@property (nonatomic, copy) NSString *deviceName;
// 最新的设备数据
@property (nonatomic, strong, readonly) NSDictionary *lastData;
@property (nonatomic, assign) BOOL online;
@property (nonatomic, assign, readonly) BOOL connected;
@property (nonatomic, strong) NSNumber *rssi;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
// 标识设备是哪种设备
@property (nonatomic, assign) InDeviceType type;

@property (nonatomic, strong) NSString *offlineTimeInfo;
@property (nonatomic, strong) NSString *offlineTime;

@property (nonatomic, assign) BOOL isSearchPhone;
@property (nonatomic, assign) BOOL searchingDevice;

+ (instancetype)device:(CBPeripheral *)peripheral;
- (void)setCoordinate:(NSString *)gps;
// 在线设备获取的是当前手机的经纬度； 离线设备获取的是保存的经纬度
- (NSString *)getGps;

// 连接方法
- (void)connectToDevice:(void (^)(DLDevice *device, NSError *error))completion;
- (void)disConnectToDevice:(void (^)(DLDevice *device, NSError *error))completion;




#pragma mark - 控制方法
- (void)write:(NSData *)data;
// 获取硬件信息
- (void)getDeviceInfo;
// 通过手机查找防丢设备
- (void)searchDevice;
// 设置断开连接通知和重连通知
- (void)setDisconnectAlert:(BOOL)disconnectAlert reconnectAlert:(BOOL)reconnectAlert;
//激活设备
- (void)activeDevice;
//警报音编码，可选 01，02，03
- (void)selecteDiconnectAlertMusic:(NSInteger)alertMusic;
@end
