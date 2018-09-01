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

#define ElectricKey @"Electric"
#define ChargingStateKey @"ChargingState"
#define DisconnectAlertKey @"DisconnectAlert"
#define ReconnectAlertKey @"ReconnectAlert"
#define AlertMusicKey @"AlertMusic"
#define AlertStatusKey @"AlertStatusKey"

#define PhoneAlertMusicKey @"PhoneAlertMusic"

#define DeviceOnlineChangeNotification @"DeviceOnlineChangeNotification"
#define DeviceSearchPhoneNotification @"DeviceSearchPhoneNotification"

@class DLDevice;
typedef void (^DidUpdateValue)(DLDevice *device, NSDictionary *value, NSError *error);

@protocol DLDeviceDelegate
- (void)device:(DLDevice *)device didUpdateData:(NSDictionary *)data;
@end

// 本地设备类
@interface DLDevice : NSObject<CBPeripheralDelegate>

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, copy) NSString *deviceName;
@property (nonatomic, copy) NSString *mac;
@property (nonatomic, strong, readonly) NSDictionary *lastData;
@property (nonatomic, weak) id<DLDeviceDelegate> delegate;
@property (nonatomic, copy) NSString *cloudID;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, assign) BOOL online;
@property (nonatomic, assign, readonly) BOOL connected;

- (BOOL)discoverServices;

- (void)setCoordinate:(NSString *)gps;
// 在线设备获取的是当前手机的经纬度； 离线设备获取的是保存的经纬度
- (NSString *)getGps;

+ (instancetype)device:(CBPeripheral *)peripheral;
- (void)write:(NSData *)data;

- (void)getDeviceInfo;
- (void)searchDevice;
- (void)setDisconnectAlert:(BOOL)disconnectAlert reconnectAlert:(BOOL)reconnectAlert;
- (void)activeDevice; //激活设备
//警报音编码，可选 01，02，03
- (void)selecteDiconnectAlertMusic:(NSInteger)alertMusic;
@end
