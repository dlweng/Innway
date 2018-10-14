//
//  InChangePasswordCell.h
//  Innway
//
//  Created by danly on 2018/10/14.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class InChangePasswordCell;
@protocol InChangePasswordCellDelegate <NSObject>
- (void)changePasswordCell:(InChangePasswordCell *)cell pwd:(NSString *)pwd;
- (void)changePasswordCellShouldReturn:(InChangePasswordCell *)cell;
@end

@interface InChangePasswordCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *pwdTextField;
@property (nonatomic, copy) NSString *placeHolder;
@property (nonatomic, copy) NSString *pwd;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, weak) id<InChangePasswordCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
