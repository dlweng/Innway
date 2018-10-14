//
//  InRootViewController.m
//  Innway
//
//  Created by danly on 2018/9/23.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InCommon.h"
#import "InRootViewController.h"
#import "InLoginViewController.h"

@interface InRootViewController ()

@property (nonatomic, assign) BOOL firstAppear;

@end

@implementation InRootViewController

+ (instancetype)rootViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"InUser" bundle:nil];
    InRootViewController *rootVC = [sb instantiateViewControllerWithIdentifier:@"InRootViewController"];
    return rootVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    self.firstAppear = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    
    if (self.firstAppear && [InCommon sharedInstance].ID > -1) {
        // 自动登陆
        self.firstAppear = NO;
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"InUser" bundle:nil];
        InLoginViewController *loginVC = [sb instantiateViewControllerWithIdentifier:@"InLoginViewController"];
        [self.navigationController pushViewController:loginVC animated:NO];
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
}



@end
