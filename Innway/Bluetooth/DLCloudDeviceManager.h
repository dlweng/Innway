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

@interface DLCloudDeviceManager : NSObject
@property (nonatomic, strong) NSMutableDictionary<NSString*, DLDevice*> *cloudDeviceList;

+ (instancetype)sharedInstance;

// 添加设备
- (void)addDevice:(NSString *)identifier completion:(DidAddDeviceEvent)completion;
- (void)deleteDevice:(NSString *)identifier completion:(DidDeleteDeviceEvent)completion;


@end
