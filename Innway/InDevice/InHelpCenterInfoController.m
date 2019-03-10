//
//  InHelpCenterInfoController.m
//  Innway
//
//  Created by danly on 2018/10/27.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InHelpCenterInfoController.h"
#import "InHelpCenterInfoCell.h"

@interface InHelpCenterInfoController ()<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, assign) InDeviceType deviceType;

@end

@implementation InHelpCenterInfoController

- (instancetype)initWithType:(InDeviceType)deviceType
{
    if (self = [super init]) {
        self.deviceType = deviceType;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNarBar];
    [self.tableView registerNib:[UINib nibWithNibName:@"InHelpCenterInfoCell" bundle:nil] forCellReuseIdentifier:@"InHelpCenterInfoCell"];
}

- (void)setupNarBar {
    self.navigationController.navigationBar.hidden = NO;
    self.navigationItem.title = @"Help Center";
    switch (self.deviceType) {
        case InDeviceCard:
            self.navigationItem.title = @"Innway Card";
            break;
        case InDeviceChip:
            self.navigationItem.title = @"Innway Chip";
            break;
        
        default:
            break;
    }
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    InHelpCenterInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InHelpCenterInfoCell" forIndexPath:indexPath];
    cell.titleLabel.textColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1];
    NSMutableParagraphStyle  *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    // 行间距设置为30
    [paragraphStyle  setLineSpacing:5];
    NSString  *info = @"";
    
    NSString *deviceName = @"card";
    switch (self.deviceType) {
//        case InDeviceTag:
//            deviceName = @"tag";
//            break;
        case InDeviceChip:
            deviceName = @"chip";
            break;
        default:
            break;
    }
    switch (indexPath.row) {
        case 0:
        {
            info = [NSString stringWithFormat:@"Attach:\nAttach Innway %@ to anything you don’t want to lose. \nConnect it to the Innway app.", deviceName];
            break;
        }
        case 1:
        {
            info = [NSString stringWithFormat:@"Ring:\nWhen the %@ and phone are connected. you can use the %@ to find your phone, or use your phone to find the %@.", deviceName, deviceName, deviceName];
            break;
        }
        case 2:
        {
            info = @"Motion History:\nFind your missing items. The app remembers when and where you last had them.";
            break;
        }
        case 3:
        {
            info = [NSString stringWithFormat:@"Camera Remote:\nThe botton on the %@ also as a camera remote. Never be left out of a group picture again. ", deviceName];
            break;
        }
        case 4:
        {
            switch (self.deviceType) {
                case InDeviceCard:
                    info = @"Rechargeble battary:\nBattery lifetime up 3 to 5 months and could be chargeable, the battery capacity percentage displays on APP. ";
                    break;
                case InDeviceChip:
                    info = @"Rechargeble battary:\nBattery lifetime up 1 to 2 months and could be chargeable, the battery capacity percentage displays on APP. ";
                    break;
                default:
                    break;
            }
            
            break;
        }
        default:
            break;
    }
    
    NSMutableAttributedString  *infoString = [[NSMutableAttributedString alloc] initWithString:info];
    [infoString  addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [info length])];
    
    // 设置Label要显示的text
    [cell.titleLabel  setAttributedText:infoString];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)goBack {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
