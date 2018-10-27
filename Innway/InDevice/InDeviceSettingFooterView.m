//
//  InDeviceSettingFooterView.m
//  Innway
//
//  Created by danly on 2018/10/13.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InDeviceSettingFooterView.h"

@interface InDeviceSettingFooterView ()

@end

@implementation InDeviceSettingFooterView

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.deleteBtn) {
        self.deleteBtn = [[UIButton alloc] init];
        [self.contentView addSubview:self.deleteBtn];
        [self.deleteBtn setBackgroundImage:[UIImage imageNamed:@"buyButton"] forState:UIControlStateNormal];
        [self.deleteBtn sizeToFit];
        self.deleteBtn.center = self.contentView.center;
        [self.deleteBtn setTitle:@"Delete device" forState:UIControlStateNormal];
        [self.deleteBtn setFont:[UIFont systemFontOfSize:18]];
        [self.deleteBtn setTitleColor:[UIColor colorWithRed:80/255.0 green:179/255.0 blue:122/255.0 alpha:1] forState:UIControlStateNormal];
    }
}

@end
