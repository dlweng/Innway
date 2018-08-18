//
//  InCommonTool.h
//  Innway
//
//  Created by danly on 2018/8/11.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InCommon : NSObject

@property (nonatomic, assign) NSInteger ID;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *pwd;
+ (instancetype)sharedInstance;

- (void)saveUserInfoWithID:(NSNumber *)ID email:(NSString *)email pwd:(NSString *)pwd;
- (void)clearUserInfo;

@end
