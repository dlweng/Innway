//
//  InDeviceMenuCell1.h
//  Innway
//
//  Created by danly on 2018/9/2.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DLDevice;
@class InDeviceMenuCell1;
@protocol InDeviceMenuCell1Delegate<NSObject>
- (void)deviceMenuCellSettingBtnDidClick:(InDeviceMenuCell1 *)cell;
@end
@interface InDeviceMenuCell1 : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *deviceSettingBtn;
@property (nonatomic, strong) DLDevice *device;
@property (nonatomic, weak) id<InDeviceMenuCell1Delegate> delegate;
@end