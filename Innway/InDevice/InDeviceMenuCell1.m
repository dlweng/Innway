//
//  InDeviceMenuCell1.m
//  Innway
//
//  Created by danly on 2018/9/2.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InDeviceMenuCell1.h"
#import "InCommon.h"

@interface InDeviceMenuCell1 ()
@property (weak, nonatomic) IBOutlet UIImageView *alertImageView;
@property (weak, nonatomic) IBOutlet UIImageView *batteryImageView;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@end

@implementation InDeviceMenuCell1

- (void)awakeFromNib {
    [super awakeFromNib];
    self.deviceSettingBtn.transform = CGAffineTransformRotate(self.deviceSettingBtn.transform, M_PI * 0.5);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

}

- (IBAction)deviceSettingDidClick:(id)sender {
    if ([self.delegate respondsToSelector:@selector(deviceMenuCellSettingBtnDidClick:)]) {
        [self.delegate deviceMenuCellSettingBtnDidClick:self];
    }
}

- (void)setDevice:(DLDevice *)device {
    _device = device;
    [self updateBattery:device];
    self.iconView.image = [UIImage imageNamed:[[InCommon sharedInstance] getImageName:device.rssi]];
    self.titleLabel.text = device.deviceName;
}

- (void)updateBattery:(DLDevice *)device {
    if (device.data.count > 0) {
        NSString *batteryImageName = @"10";
        NSInteger battery = [device.data integerValueForKey:ElectricKey defaultValue:0];
        if (battery > 90) {
            batteryImageName = @"100";
        }
        else if (battery > 80) {
            batteryImageName = @"90";
        }
        else if (battery > 70) {
            batteryImageName = @"80";
        }
        else if (battery > 60) {
            batteryImageName = @"70";
        }
        else if (battery > 50) {
            batteryImageName = @"60";
        }
        else if (battery > 40) {
            batteryImageName = @"50";
        }
        else if (battery > 30) {
            batteryImageName = @"40";
        }
        else if (battery > 20) {
            batteryImageName = @"30";
        }
        else if (battery > 10) {
            batteryImageName = @"20";
        } else if(battery >= 5){
            batteryImageName = @"10";
        } else if(battery > 0){
            batteryImageName = @"5";
        } else if(battery == 0){
            batteryImageName = @"0";
        }
        if (batteryImageName.integerValue == 5) {
            self.batteryImageView.hidden = YES;
            self.alertImageView.hidden = NO;
        }
        else {
            self.alertImageView.hidden = YES;
            self.batteryImageView.hidden = NO;
            [self.batteryImageView setImage:[UIImage imageNamed:batteryImageName]];
        }
    }
}

@end
