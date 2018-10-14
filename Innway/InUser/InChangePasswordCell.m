//
//  InChangePasswordCell.m
//  Innway
//
//  Created by danly on 2018/10/14.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InChangePasswordCell.h"

@interface InChangePasswordCell ()<UITextFieldDelegate>

@end

@implementation InChangePasswordCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.pwdTextField.delegate = self;

}

- (void)setPlaceHolder:(NSString *)placeHolder {
    _placeHolder = placeHolder;
    self.pwdTextField.placeholder = placeHolder;
}

- (void)setPwd:(NSString *)pwd {
    _pwd = pwd;
    self.pwdTextField.text = pwd;
}

- (IBAction)pwdValueChange:(UITextField *)sender {
    _pwd = sender.text;
    if ([self.delegate respondsToSelector:@selector(changePasswordCell:pwd:)]) {
        [self.delegate changePasswordCell:self pwd:sender.text];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([self.delegate respondsToSelector:@selector(changePasswordCellShouldReturn:)]) {
        [self.delegate changePasswordCellShouldReturn:self];
    }
    return YES;
}

@end
