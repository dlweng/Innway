//
//  InBaseViewController.m
//  Innway
//
//  Created by danly on 2018/9/23.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InBaseViewController.h"

@interface InBaseViewController ()

@end

@implementation InBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
}

- (void)goBack {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


@end
