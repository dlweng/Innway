//
//  InRegisterViewController.m
//  Innway
//
//  Created by danly on 2018/8/4.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import "InRegisterViewController.h"
#import "InUserTableViewController.h"
#import <AFNetworking.h>
#import "InAlertTool.h"

@interface InRegisterViewController ()

@property (weak, nonatomic) IBOutlet UIButton *registerBtn;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *pwd;

@end

@implementation InRegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"注册账户";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    
    //设置按钮的圆弧
    self.registerBtn.layer.masksToBounds = YES;
    self.registerBtn.layer.cornerRadius = 25;
}

- (void)goBack {
    if (self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)registerBtnDidClick:(UIButton *)sender {
    if (self.email.length == 0) {
        [InAlertTool showAlertWithTip:@"请输入邮箱"];
        return;
    }
    else if (self.pwd.length == 0) {
        [InAlertTool showAlertWithTip:@"请输入密码"];
        return;
    }
    
    NSLog(@"开始注册，邮箱: %@, 密码: %@", self.email, self.pwd);
    // 初始化Request
    NSURL *url = [NSURL URLWithString:@"http://121.12.125.214:1050/GetData.ashx"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    // http body
    NSDictionary *parameters = @{@"username":self.email, @"password":self.pwd, @"action":@"register"};
    NSMutableString *body = [NSMutableString string];
    for (NSString *key in [parameters allKeys]) {
        [body appendFormat:@"&;%@=%@", key, parameters[key]];
    }
    [body deleteCharactersInRange:NSMakeRange(0, 2)]; // 删除多余的&;号
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    // http method
    [request setHTTPMethod:@"POST"];
    // http header
    NSString *bodyLength = [NSString stringWithFormat:@"%lu", (unsigned long)body.length];
    [request addValue:bodyLength forHTTPHeaderField:@"Content-Length"];
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    NSLog(@"请求方法:%@", request.HTTPMethod);
    NSLog(@"URL:%@", request.URL);
    NSLog(@"请求头:%@", request.allHTTPHeaderFields);
    NSLog(@"请求体:%@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
     NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        NSLog(@"请求结果：data = %@, message = %@, error = %@", dic, dic[@"message"], error);
    }];
    [dataTask resume];
}

//- (IBAction)registerBtnDidClick:(UIButton *)sender {
//    if (self.email.length == 0) {
//        [InAlertTool showAlertWithTip:@"请输入邮箱"];
//        return;
//    }
//    else if (self.pwd.length == 0) {
//        [InAlertTool showAlertWithTip:@"请输入密码"];
//        return;
//    }
//
////    NSURL *url = [NSURL URLWithString:@"http://121.12.125.214:1050/GetData.ashx"];
////    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
////    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
////    [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:<#(NSError * _Nullable __autoreleasing * _Nullable)#>]
//    NSLog(@"开始注册，邮箱: %@, 密码: %@", self.email, self.pwd);
//    // 初始化Request
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://121.12.125.214:1050/GetData.ashx"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:15.0];
//    // http body
//    NSDictionary *parameters = @{@"username":self.email, @"password":self.pwd, @"action":@"register"};
//    NSMutableString *body = [NSMutableString string];
//    for (NSString *key in [parameters allKeys]) {
//        [body appendFormat:@"&;%@=%@", key, parameters[key]];
//    }
//    [body deleteCharactersInRange:NSMakeRange(0, 2)]; // 删除多余的&;号
//    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
//    // http method
//    [request setHTTPMethod:@"POST"];
//    // http header
//    NSString *bodyLength = [NSString stringWithFormat:@"%lu", (unsigned long)body.length];
//    [request addValue:bodyLength forHTTPHeaderField:@"Content-Length"];
//    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
//
//    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration: [NSURLSessionConfiguration defaultSessionConfiguration]];
//    AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
//    serializer.acceptableContentTypes = [NSSet setWithObjects:
//                                         @"text/plain",
//                                         @"application/json",
//                                         @"text/html", nil];
//    NSLog(@"请求体: %@", body);
//    manager.responseSerializer = serializer;
//    // 构建请求任务
//    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id _Nullable responseObject, NSError * _Nullable error) {
//        if (error) {
//            // 请求失败
//            NSLog(@"Request failed with reason '%@'", [error localizedDescription]);
//        } else {
//            // 请求成功
//            NSString *message = responseObject[@"ErrorMessage"];
//            NSLog(@"请求成功:responseObject = %@, ErrorMessage = %@", responseObject, message);
//
//        }
//    }];
//    // 发起请求
//    [dataTask resume];
//}


//- (IBAction)registerBtnDidClick:(UIButton *)sender {
//    if (self.email.length == 0) {
//        [InAlertTool showAlertWithTip:@"请输入邮箱"];
//        return;
//    }
//    else if (self.pwd.length == 0) {
//        [InAlertTool showAlertWithTip:@"请输入密码"];
//        return;
//    }
//
//    NSDictionary *parameters = @{@"username":self.email, @"password":self.pwd};
//    NSLog(@"开始注册，邮箱: %@, 密码: %@", self.email, self.pwd);
//    [[AFHTTPSessionManager manager] POST:@"http://111.230.192.125/user/register" parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
//            NSNumber *code = responseObject[@"code"];
//            NSString *message = responseObject[@"message"];
//            if (code.integerValue == 200) {
//                [InAlertTool showAlertAutoDisappear:@"注册成功"];
//            }
//            else if (code.integerValue == 500) {
//                [InAlertTool showAlertAutoDisappear:[NSString stringWithFormat:@"%@", message]];
//            }
////             NSLog(@"注册结果：code = %@, message = %@", code, message);
//        }
//        NSLog(@"注册结果：task = %@, responseObject = %@", task, responseObject);
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        NSLog(@"注册结果：task = %@, error = %@", task, error);
//        [InAlertTool showAlertAutoDisappear:@"网络连接异常"];
//    }];
//}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[InUserTableViewController class]]) {
        InUserTableViewController *userTableViewVC = segue.destinationViewController;
        userTableViewVC.userViewType = InUserWithPassword;
        userTableViewVC.emailValueChanging = ^(NSString *email) {
            self.email = email;
//            NSLog(@"邮箱: %@", self.email);
        };
        userTableViewVC.pwdValueChanging = ^(NSString *pwd) {
            self.pwd = pwd;
//            NSLog(@"密码: %@", self.pwd);
        };
    }
}


@end
