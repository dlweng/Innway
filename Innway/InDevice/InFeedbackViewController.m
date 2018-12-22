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
    self.navigationItem.title = @"Contact Innway";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStylePlain target:self action:@selector(sendFeedback)];
}

- (void)sendFeedback {
    [self.textView resignFirstResponder];
    if (self.textView.text.length == 0) {
        [InAlertView showAlertWithTitle:@"Information" message:@"Please leave your feedback" confirmTitle:nil confirmHanler:nil];
    }
    else {
        [InAlertTool showHUDAddedTo:self.view animated:YES];
        NSDictionary* body = @{@"Uid":[NSString stringWithFormat:@"%zd", common.ID], @"Context":self.textView.text, @"action":@"ADDFeedback"};
        [InCommon sendHttpMethod:@"POST" URLString:httpDomain body:body completionHandler:^(NSURLResponse *response, NSDictionary *responseObject, NSError * _Nullable error) {
            NSLog(@"发送意见反馈结果:responseObject = %@, error = %@", responseObject, error);
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            NSInteger code = [responseObject integerValueForKey:@"code" defaultValue:500];
            NSString *message;
            if (code == 200) {
                message = @"Thank you for your feedback. We will get back to you as soon as we can.";
                [InAlertView showAlertWithTitle:@"Feedback sent" message:message confirmTitle:@"OK" confirmHanler:nil];
            }
            else {
                if (error && error.code == -1) {
                    message = @"Network connection lost";
                }
                else {
                    message = @"Feedback submission failure";
                }
                [InAlertView showAlertWithTitle:@"Information" message:message confirmTitle:nil confirmHanler:nil];
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
