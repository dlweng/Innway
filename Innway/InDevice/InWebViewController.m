//
//  InWebViewController.m
//  Innway
//
//  Created by danlypro on 2018/12/11.
//  Copyright © 2018 innwaytech. All rights reserved.
//

#import "InWebViewController.h"
#import "InCommon.h"

@interface InWebViewController ()<UIWebViewDelegate>

@property (nonatomic, weak) UIWebView *webView;
@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, copy) NSString *title;

@end

@implementation InWebViewController

- (instancetype)initWithTitle:(NSString *)title UrlString:(NSString *)urlString {
    if (self = [super init]) {
        self.urlString = urlString;
        self.title = title;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNarBar];
    
    UIWebView *tmpWebView = [[UIWebView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:tmpWebView];
    self.webView = tmpWebView;
    self.webView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [InAlertTool showHUDAddedTo:self.view animated:YES];
    if (self.urlString) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]];
        [self.webView loadRequest:request];
    }
}

- (void)setupNarBar {
    self.navigationItem.title = self.title;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"加载完成");
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

//- (void)webViewDidStartLoad:(UIWebView *)webView {
//    NSLog(@"加载完成");
//    [MBProgressHUD hideHUDForView:self.view animated:YES];
//}

- (void)goBack {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}



@end
