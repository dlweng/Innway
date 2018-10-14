//
//  InDeviceListCell.m
//  Innway
//
//  Created by danly on 2018/8/4.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InOldDeviceListCell.h"
#import "InCommon.h"

@interface InOldDeviceListCell()
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceIDLabel;
@end

@implementation InOldDeviceListCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

#pragma mark - Properity
- (void)setDeviceName:(NSString *)deviceName {
    _deviceName = deviceName;
    self.nameLabel.text = deviceName;
}

- (void)setDeviceID:(NSString *)deviceID {
    _deviceID = deviceID;
    self.deviceIDLabel.text = deviceID;
}

- (void)setRssi:(NSNumber *)rssi {
    NSString *imageName = [[InCommon sharedInstance] getImageName:rssi];
    self.iconView.image = [UIImage imageNamed:imageName];
}

@end
