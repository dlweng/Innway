//
//  InFeedbackViewController.m
//  Innway
//
//  Created by danly on 2018/10/27.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InFeedbackViewController.h"
#import "InCommon.h"

@interface InFeedbackViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;

@end

@implementation InFeedbackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNarBar];
    if ([InCommon isIPhoneX]) {
        self.topConstraint.constant += 20;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.textView becomeFirstResponder];
}

- (void)setupNarBar {
    self.navigationController.navigationBar.hidden = NO;
    self.navigationItem.title = @"Feedback";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStylePlain target:self action:@selector(sendFeedback)];
}

- (void)sendFeedback {
    [self.textView resignFirstResponder];
    if (self.textView.text.length == 0) {
        [InAlertView showAlertWithTitle:@"Information" message:@"请输入反馈信息" confirmHanler:nil];
    }
    else {
        [InAlertTool showHUDAddedTo:self.view animated:YES];
        NSDictionary* body = @{@"Uid":[NSString stringWithFormat:@"%zd", common.ID], @"Context":self.textView.text, @"action":@"ADDFeedback"};
        [InCommon sendHttpMethod:@"POST" URLString:httpDomain body:body completionHandler:^(NSURLResponse *response, NSDictionary *responseObject, NSError * _Nullable error) {
            NSLog(@"发送意见反馈结果:responseObject = %@, error = %@", responseObject, error);
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if (error) {
                [InAlertView showAlertWithTitle:@"Information" message:error.localizedDescription confirmHanler:nil];
            }
            else {
                NSInteger code = [responseObject integerValueForKey:@"code" defaultValue:500];
                if (code == 200) {
                    NSLog(@"发送意见反馈成功");
                    [InAlertView showAlertWithTitle:@"Information" message:@"发送意见反馈成功" confirmHanler:nil];
                }
                else {
                    NSString *message = [responseObject stringValueForKey:@"message" defaultValue:@"发送意见反馈失败"];
                    [InAlertView showAlertWithTitle:@"Information" message:message confirmHanler:nil];
                }
            }
        }];
    }
    NSLog(@"发送反馈邮件, textView = %@", self.textView.text);
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.textView resignFirstResponder];
}

- (void)goBack {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
