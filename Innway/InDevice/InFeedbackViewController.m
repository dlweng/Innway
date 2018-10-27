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
