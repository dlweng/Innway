//
//  InDeviceMenuCell1.m
//  Innway
//
//  Created by danly on 2018/9/2.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InDeviceMenuCell1.h"

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


@end
