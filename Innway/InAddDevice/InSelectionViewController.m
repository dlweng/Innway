//
//  InSelectionViewController.m
//  Innway
//
//  Created by danly on 2018/10/1.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InSelectionViewController.h"
#import "InSearchDeviceViewController.h"
#import "inCommon.h"

@interface InSelectionViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray *arr;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation InSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.arr = @[@{@"image": @"tag", @"title": @"Innway Tag"},
                 @{@"image": @"chip", @"title": @"Innway chip"},
                 @{@"image": @"Card", @"title": @"Innway Card"}];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    
    self.navigationItem.title = @"Add a new Innway";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView setContentOffset:CGPointZero animated:NO];
    });
}

- (void)goBack {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    NSDictionary *dic = self.arr[indexPath.row];
    cell.imageView.image = [UIImage imageNamed:dic[@"image"]];
    cell.textLabel.text = dic[@"title"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    common.searchDeviceType = indexPath.row;
    NSLog(@"去搜索设备类型: %zd", common.searchDeviceType);
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController pushViewController:[InSearchDeviceViewController searchDeviceViewController] animated:YES];
    }
}

- (IBAction)buyNewInnway {
    NSLog(@"跳转到购买设备链接");
}




@end