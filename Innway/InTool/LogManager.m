//
//  LogManager.m
//  TestLog
//
//  Created by danlypro on 2019/4/21.
//  Copyright © 2019 danlypro. All rights reserved.
//

#import "LogManager.h"
#import <pthread/pthread.h>

static pthread_mutex_t _processFileHandler = PTHREAD_MUTEX_INITIALIZER;

// 日志保留最大天数
static const int LogMaxSaveDay = 2;
// 日志文件保存目录
static const NSString* LogFilePath = @"/Documents/Log/";

// 最大的日志文件大小10MB
static const long long maxFileSize = 30 * 1024 * 1024;
//static const long long maxFileSize = 1000;

@interface LogManager()

// 日期格式化
@property (nonatomic,retain) NSDateFormatter* dateFormatter;
// 时间格式化
@property (nonatomic,retain) NSDateFormatter* timeFormatter;

// 日志的目录路径
@property (nonatomic,copy) NSString* basePath;
@property (nonatomic, copy) NSString *oldPath;

@end

@implementation LogManager

/**
 *  获取单例实例
 *
 *  @return 单例实例
 */
+ (instancetype) sharedInstance{
    
    static LogManager* instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = [[LogManager alloc]init];
        }
    });
    
    return instance;
}

// 获取当前时间
+ (NSDate*)getCurrDate{
    
    NSDate *date = [NSDate date];
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate: date];
    NSDate *localeDate = [date dateByAddingTimeInterval: interval];
    
    return localeDate;
}

#pragma mark - Init

- (instancetype)init{
    
    self = [super init];
    if (self) {
        
        // 创建日期格式化
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc]init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        // 设置时区，解决8小时
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        self.dateFormatter = dateFormatter;
        
        // 创建时间格式化
        NSDateFormatter* timeFormatter = [[NSDateFormatter alloc]init];
        [timeFormatter setDateFormat:@"HH:mm:ss"];
        [timeFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        self.timeFormatter = timeFormatter;
        
        // 日志的目录路径
        self.basePath = [NSString stringWithFormat:@"%@%@",NSHomeDirectory(),LogFilePath];
        
        [self clearExpiredLog];
    }
    return self;
}

/**
 获取文件大小

 @return
 */
#pragma mark - Method

/**
 写入日志

 @param funcName 方法名称
 @param line 行数
 @param logStr 日志消息
 */
- (void)logInfo:(const char *)funcName line:(int)line logStr:(NSString*)logStr {
#pragma mark - 写入日志
    if (logStr) {
        // 异步执行
        dispatch_async(dispatch_queue_create("writeLog", nil), ^{
            
            // 获取当前日期做为文件名
            NSString* fileName = [self.dateFormatter stringFromDate:[NSDate date]];
            NSString* filePath = [NSString stringWithFormat:@"%@%@.txt",self.basePath,fileName];
            
            // [时间]-[模块]-日志内容
            NSString* timeStr = [self.timeFormatter stringFromDate:[LogManager getCurrDate]];
            NSString* writeStr = [NSString stringWithFormat:@"[%@]%s:%d,  [%@]\n",timeStr, funcName, line, logStr];
            
            //先删除过大的文件
            [self clearFullLog];
            // 写入数据
            [self writeFile:filePath stringData:writeStr];
        });
    }
}


/**
 *  清空过期的日志
 */
- (void)clearExpiredLog{
    [self lockFile];
    // 获取日志目录下的所有文件
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.basePath error:nil];
    for (NSString* file in files) {
        
        NSDate* date = [self.dateFormatter dateFromString:file];
        if (date) {
            NSTimeInterval oldTime = [date timeIntervalSince1970];
            NSTimeInterval currTime = [[LogManager getCurrDate] timeIntervalSince1970];
            
            NSTimeInterval second = currTime - oldTime;
            int day = (int)second / (24 * 3600);
            if (day >= LogMaxSaveDay) {
                // 删除该文件
                [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",self.basePath,file] error:nil];
                NSLog(@"[%@]日志文件已被删除！",file);
            }
        }
    }
    [self unlockFile];
}

/**
 *  写入字符串到指定文件，默认追加内容
 *
 *  @param filePath   文件路径
 *  @param stringData 待写入的字符串
 */
- (void)writeFile:(NSString*)filePath stringData:(NSString*)stringData{
    // 待写入的数据
    NSData* writeData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
    
    // NSFileManager 用于处理文件
    BOOL createPathOk = YES;
    [self lockFile];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[filePath stringByDeletingLastPathComponent] isDirectory:&createPathOk]) {
        // 目录不存先创建
        [[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        // 文件不存在，直接创建文件并写入
        [writeData writeToFile:filePath atomically:NO];
    }else{
        
        // NSFileHandle 用于处理文件内容
        // 读取文件到上下文，并且是更新模式
        NSFileHandle* fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
        
        // 跳到文件末尾
        [fileHandler seekToEndOfFile];
        
        // 追加数据
        [fileHandler writeData:writeData];
        
        // 关闭文件
        [fileHandler closeFile];
    }
    [self unlockFile];
}


- (long long)fileSizeAtPath:(NSString*)filePath
{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}


/**
 当前写入的文件大于10M时，若存在old.txt文件，删除，并将当前的文件保存到old.txt中
 删除当前文件，重新写入
 */
- (void)clearFullLog {
    NSString *fileName = [self.dateFormatter stringFromDate:[NSDate date]];
    NSString* newPath = [NSString stringWithFormat:@"%@%@.txt",self.basePath,fileName];
    if ([self fileSizeAtPath:newPath] >= maxFileSize) {
        // 文件大于10M
        [self lockFile];
        NSFileManager* manager = [NSFileManager defaultManager];
        NSString *oldPath = [NSString stringWithFormat:@"%@%@_old.txt", self.basePath, fileName];
        // 存在旧文件，删除
        if ([manager fileExistsAtPath:oldPath]) {
            [manager removeItemAtPath:oldPath error:nil];
        }
        [manager copyItemAtPath:newPath toPath:oldPath error:nil];
        [manager removeItemAtPath:newPath error:nil];
        [self unlockFile];
    }
}

- (void)lockFile {
    pthread_mutex_lock(&_processFileHandler);
}

- (void)unlockFile {
    pthread_mutex_unlock(&_processFileHandler);
}


@end
