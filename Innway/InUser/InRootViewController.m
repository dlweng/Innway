//
//  InRootViewController.m
//  Innway
//
//  Created by danly on 2018/9/23.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InRootViewController.h"
#import "InLoginViewController.h"
#import "InCommon.h"

@interface InRootViewController ()

@property (nonatomic, assign) BOOL firstAppear;

@end

@implementation InRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.firstAppear && [InCommon sharedInstance].ID > -1) {
        self.firstAppear = NO;
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"InUser" bundle:nil];
        InLoginViewController *loginVC = [sb instantiateViewControllerWithIdentifier:@"InLoginViewController"];
        [self.navigationController pushViewController:loginVC animated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
}



@end
