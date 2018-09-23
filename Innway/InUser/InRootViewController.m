//
//  InRootViewController.m
//  Innway
//
//  Created by danly on 2018/9/23.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InRootViewController.h"
#import "InCommon.h"

@interface InRootViewController ()

@end

@implementation InRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    if (common.email.length > 0 && common.pwd.length > 0) {
        
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
}



@end
