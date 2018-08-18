//
//  InCommonTool.m
//  Innway
//
//  Created by danly on 2018/8/11.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InCommon.h"

@interface InCommon ()

@end

@implementation InCommon

+ (instancetype)sharedInstance {
    static InCommon *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[InCommon alloc] init];
        [instance getUserInfo];
    });
    return instance;
}

- (void)saveUserInfoWithID:(NSNumber *)ID email:(NSString *)email pwd:(NSString *)pwd {
    self.ID = ID.integerValue;
    self.email = email;
    self.pwd = pwd;
    if (self.ID && self.email && self.pwd) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:ID forKey:@"ID"];
        [defaults setValue:email forKey:@"email"];
        [defaults setValue:pwd forKey:@"pwd"];
        [defaults synchronize];
    }
}

- (void)getUserInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *IDNumber = [defaults valueForKey:@"ID"];
    if (IDNumber) {
        self.ID = IDNumber.integerValue;
        self.email = [defaults valueForKey:@"email"];
        self.pwd = [defaults valueForKey:@"pwd"];
    }
    else {
        self.ID = -1;
        self.email = nil;
        self.pwd = nil;
    }
}

- (void)clearUserInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"ID"];
    [defaults removeObjectForKey:@"email"];
    [defaults removeObjectForKey:@"pwd"];
    [defaults synchronize];
    self.ID = -1;
    self.email = nil;
    self.pwd = nil;
}

@end
