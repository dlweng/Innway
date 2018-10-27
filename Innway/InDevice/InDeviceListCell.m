//
//  InDeviceMenuCell1.m
//  Innway
//
//  Created by danly on 2018/9/2.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InDeviceListCell.h"
#import "InCommon.h"

@interface InDeviceListCell ()
@property (weak, nonatomic) IBOutlet UIImageView *alertImageView;
@property (weak, nonatomic) IBOutlet UIImageView *batteryImageView;
@property (weak, nonatomic) IBOutlet UIImageView *rssiView;
@property (weak, nonatomic) IBOutlet UIImageView *chipView;
@property (weak, nonatomic) IBOutlet UIImageView *cardView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@end

@implementation InDeviceListCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.deviceSettingBtn.transform = CGAffineTransformRotate(self.deviceSettingBtn.transform, M_PI * 0.5);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

}

- (IBAction)deviceSettingDidClick:(id)sender {
    if ([self.delegate respondsToSelector:@selector(deviceListCellSettingBtnDidClick:)]) {
        [self.delegate deviceListCellSettingBtnDidClick:self];
    }
}

- (void)setDevice:(DLDevice *)device {
    _device = device;
    [self updateBattery:device];
    self.rssiView.image = [UIImage imageNamed:[[InCommon sharedInstance] getImageName:device.rssi]];
    self.titleLabel.text = device.deviceName;
    switch (_device.type) {
        case InDeviceTag:
        {
            self.chipView.image = [UIImage imageNamed:@"greentag"];
            self.chipView.hidden = NO;
            self.cardView.hidden = YES;
            break;
        }
        case InDeviceChip:
        {
            self.chipView.image = [UIImage imageNamed:@"greenchip"];
            self.chipView.hidden = NO;
            self.cardView.hidden = YES;
            break;
        }
        default:
        {
            self.chipView.hidden = YES;
            self.cardView.hidden = NO;
            break;
        }
    }
}

- (void)updateBattery:(DLDevice *)device {
    if (device.lastData.count > 0) {
        NSString *batteryImageName = @"charge";
        NSInteger charge = [device.lastData integerValueForKey:ChargingStateKey defaultValue:0];
        if (!charge) {
            NSInteger battery = [device.lastData integerValueForKey:ElectricKey defaultValue:0];
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
