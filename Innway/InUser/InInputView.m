//
//  InInputView.m
//  Innway
//
//  Created by danly on 2018/9/23.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InInputView.h"

@implementation InInputView

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.borderWidth = 1.0f;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
}

@end
