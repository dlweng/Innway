//
//  DLCloudDeviceManager.h
//  Bluetooth
//
//  Created by danly on 2018/8/19.
//  Copyright © 2018年 date. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DLCentralManager.h"
#import "DLDevice.h"

@class DLCloudDeviceManager;
typedef void (^DidAddDeviceEvent)(DLCloudDeviceManager *manager, DLDevice *device, NSError *error);
typedef void (^DidDeleteDeviceEvent)(DLCloudDeviceManager *manager, NSError *error);
typedef void (^DidGetCloudListEvent)(DLCloudDeviceManager *manager, NSDictionary *cloudList);

@interface DLCloudDeviceManager : NSObject
@property (nonatomic, strong) NSMutableDictionary<NSString*, DLDevice*> *cloudDeviceList;

+ (instancetype)sharedInstance;

// 添加设备
- (void)addDevice:(NSString *)mac completion:(DidAddDeviceEvent)completion;
- (void)deleteDevice:(NSString *)mac completion:(DidDeleteDeviceEvent)completion;

// 获取云端的设备列表
- (void)getHTTPCloudDeviceListCompletion:(DidGetCloudListEvent)completion;
//根据新发现的设备更新云端列表
- (void)updateCloudList;

// 注销账户时，需要断开所有连接的设备，以及删除本地保存的云端列表
- (void)deleteCloudList;

@end
