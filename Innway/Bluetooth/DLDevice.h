//
//  DLPeripheral.h
//  Bluetooth
//
//  Created by danly on 2018/8/18.
//  Copyright © 2018年 date. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define ElectricKey @"Electric"
#define ChargingStateKey @"ChargingState"
#define DisconnectAlertKey @"DisconnectAlert"
#define ReconnectAlertKey @"ReconnectAlert"
#define AlertMusicKey @"AlertMusic"
#define AlertStatusKey @"AlertStatusKey"

#define PhoneAlertMusicKey @"PhoneAlertMusic"


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

//@property (nonatomic, assign) NSInteger cloudID;
//@property (nonatomic, copy) NSString *mac;
//// 标识设备是否在线
//@property (nonatomic, assign) BOOL online;
// 返回true，成功发现服务； 返回false，发现失败
- (BOOL)discoverServices;

+ (instancetype)device:(CBPeripheral *)peripheral;
- (void)write:(NSData *)data;

- (void)getDeviceInfo;
- (void)searchDevice;
- (void)setDisconnectAlert:(BOOL)disconnectAlert reconnectAlert:(BOOL)reconnectAlert;
- (void)activeDevice; //激活设备
//警报音编码，可选 01，02，03
- (void)selecteDiconnectAlertMusic:(NSInteger)alertMusic;
@end
