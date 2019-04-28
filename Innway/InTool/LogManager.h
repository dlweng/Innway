//
//  LogManager.h
//  TestLog
//
//  Created by danlypro on 2019/4/21.
//  Copyright © 2019 danlypro. All rights reserved.
//

#import <Foundation/Foundation.h>

//#if DEBUG
//#define saveLog(format, ...) [[LogManager sharedInstance] logInfo:__func__ line:__LINE__ logStr:[NSString stringWithFormat:format, ## __VA_ARGS__]];

//#else
#define saveLog(format, ...)
//#endif

@interface LogManager : NSObject

/**
 *  获取单例实例
 *
 *  @return 单例实例
 */
+ (instancetype) sharedInstance;

#pragma mark - Method
/**
 写入日志
 
 @param funcName 方法名称
 @param line 行数
 @param logStr 日志消息
 */
- (void)logInfo:(const char *)funcName line:(int)line logStr:(NSString*)logStr;

/**
 *  清空过期的日志
 */
- (void)clearExpiredLog;


@end
