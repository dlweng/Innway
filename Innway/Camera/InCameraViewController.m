//
//  InCameraViewController.m
//  Camera
//
//  Created by danlypro on 2018/12/8.
//  Copyright © 2018 danlypro. All rights reserved.
//

#import "InCameraViewController.h"
#import "LLSimpleCamera.h"
#import "LibraryViewController.h"
#import "InCommon.h"
#import "NSTimer+InTimer.h"

@interface InCameraViewController()<LibraryViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *cameraBodyView;
@property (weak, nonatomic) IBOutlet UIButton *flashBtn;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *goBackBtn;
@property (weak, nonatomic) IBOutlet UIButton *goLibraryBtn;


@property (weak, nonatomic) IBOutlet UIButton *changeCameraBtn;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoBtn;
@property (weak, nonatomic) IBOutlet UIButton *switchModeBtn;



@property (strong, nonatomic) LLSimpleCamera *camera;

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, assign) NSInteger recodeTime;

@end

@implementation InCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.camera = [[LLSimpleCamera alloc] initWithQuality:AVCaptureSessionPresetHigh
                                                 position:LLCameraPositionRear
                                             videoEnabled:YES];
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
     [self.camera attachToViewController:self view:self.cameraBodyView withFrame:CGRectMake(0, 0, screenSize.width, screenSize.height-93)];
    self.camera.fixOrientationAfterCapture = NO;
    self.camera.tapToFocus = NO;
    __weak typeof(self) weakSelf = self;
    [self.camera setOnDeviceChange:^(LLSimpleCamera *camera, AVCaptureDevice * device) {
        //进入拍照界面的时候，会先回调这里
        NSLog(@"前后摄像头切换");
        if([camera isFlashAvailable]) {
            weakSelf.flashBtn.hidden = NO;
            if(camera.flash == LLCameraFlashOff) {
                weakSelf.flashBtn.selected = NO;
            }
            else {
                weakSelf.flashBtn.selected = YES;
            }
        }
        else {
            weakSelf.flashBtn.hidden = YES;
        }
    }];
    
    [self.camera setOnError:^(LLSimpleCamera *camera, NSError *error) {
        NSLog(@"捕捉到错误: error = %@", error);
    }];
    
    [self.takePhotoBtn setImage:[UIImage imageNamed:@"photoGrayCamera.png"] forState:UIControlStateNormal];
    self.switchModeBtn.selected = NO;
    self.timeLabel.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.camera start];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    NSLog(@"摄像界面被销毁");
}

- (void)enterBackground {
    if (self.switchModeBtn.selected && self.camera.isRecording) {
        //进入后台的时候还在录像，停止录像
        [self takeAPhoto];
    }
}

- (void)image:(UIImage *)image didFinishSaveImageWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSLog(@"保存图片结果: image = %@, error = %@, contextInfo = %@", image, error, contextInfo);
}

- (IBAction)flashBtnDidClick {
    NSLog(@"闪光灯");
    if(self.camera.flash == LLCameraFlashOff) {
        BOOL done = [self.camera updateFlashMode:LLCameraFlashOn];
        if(done) {
            self.flashBtn.selected = YES;
            self.flashBtn.tintColor = [UIColor whiteColor];
        }
    }
    else {
        BOOL done = [self.camera updateFlashMode:LLCameraFlashOff];
        if(done) {
            self.flashBtn.selected = NO;
            self.flashBtn.tintColor = [UIColor grayColor];
        }
    }
}

- (IBAction)changeCamera {
    NSLog(@"切换镜头方向");
    if([LLSimpleCamera isFrontCameraAvailable] && [LLSimpleCamera isRearCameraAvailable])  {
        [self.camera togglePosition];
    }
}


- (IBAction)goToLibrary {
    NSLog(@"进入相册");
    LibraryViewController *libraryVC = [[LibraryViewController alloc] init];
    libraryVC.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:libraryVC];
    
    // 设置状态栏和导航栏  设置状态栏是因为在IPhone5s上状态栏会消失
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [InCommon setNavgationBar:nav.navigationBar];
    NSMutableDictionary *titleTextAttributes = [NSMutableDictionary dictionary];
    titleTextAttributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
    nav.navigationBar.titleTextAttributes = titleTextAttributes;
    nav.navigationBar.tintColor = [UIColor whiteColor];
    
    
    [self presentViewController:nav animated:YES completion:nil];
    // 界面切换要回调
    if ([self.delegate respondsToSelector:@selector(cameraViewControllerDidChangeToLibrary:)]) {
        [self.delegate cameraViewControllerDidChangeToLibrary:YES];
    }
}

- (IBAction)takePhoto {
    NSLog(@"拍照");
    [self takeAPhoto];
}


- (IBAction)goBackAction {
    NSLog(@"返回");
    if ([self.delegate respondsToSelector:@selector(cameraViewControllerDidClickGoBack:)]) {
        [self.delegate cameraViewControllerDidClickGoBack:self];
    }
}

- (void)libraryViewControllerDidClickGoBack:(LibraryViewController *)vc {
    [vc dismissViewControllerAnimated:YES completion:nil];
    if ([self.delegate respondsToSelector:@selector(cameraViewControllerDidChangeToLibrary:)]) {
        [self.delegate cameraViewControllerDidChangeToLibrary:NO];
    }
}

- (void)takeAPhoto {
    __weak typeof(self) weakSelf = self;
    if (!self.switchModeBtn.selected) {
        // 未选中， 拍照功能
        [self.camera capture:^(LLSimpleCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error) {
            NSLog(@"获取照片, image = %@, metadata = %@, error = %@", image, metadata, error);
            if(!error) {
                // 相机拍完照进入保存
                UIImageWriteToSavedPhotosAlbum(image, weakSelf, @selector(image:didFinishSaveImageWithError:contextInfo:), (__bridge void *)weakSelf);
            }
            else {
                NSLog(@"An error has occured: %@", error);
            }
        } exactSeenImage:YES];
    }
    else {
        // 选中，摄像机功能
        if (!self.camera.isRecording) {
            // 开启录像
            self.switchModeBtn.userInteractionEnabled = NO;
            self.goLibraryBtn.userInteractionEnabled = NO;
            self.goBackBtn.userInteractionEnabled = NO;
            self.flashBtn.hidden = YES;
            self.changeCameraBtn.hidden = YES;
            self.timeLabel.hidden = NO;
            [self startTimer];
            [self.takePhotoBtn setImage:[UIImage imageNamed:@"stopRecode"] forState:UIControlStateNormal];
            NSURL *documentuURL =  [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
            NSURL *outputURL = [[documentuURL
                                 URLByAppendingPathComponent:@"test1"] URLByAppendingPathExtension:@"mov"];
            [self.camera startRecordingWithOutputUrl:outputURL didRecord:^(LLSimpleCamera *camera, NSURL *outputFileUrl, NSError *error) {
                UISaveVideoAtPathToSavedPhotosAlbum(outputURL.path, weakSelf, @selector(video:didFinishSavingWithError:contextInfo:), nil);
            }];
        }
        else {
            // 关闭录像
            self.timeLabel.hidden = YES;
            self.changeCameraBtn.hidden = NO;
            self.flashBtn.hidden = NO;
            self.switchModeBtn.userInteractionEnabled = YES;
            self.goLibraryBtn.userInteractionEnabled = YES;
            self.goBackBtn.userInteractionEnabled = YES;
            [self stopTimer];
            [self.takePhotoBtn setImage:[UIImage imageNamed:@"startRecode"] forState:UIControlStateNormal];
            [self.camera stopRecording];
        }
    }
}

- (IBAction)switchModeBtnDidClick {
    self.switchModeBtn.selected = !self.switchModeBtn.selected;
    if (self.switchModeBtn.selected) {
        [self.takePhotoBtn setImage:[UIImage imageNamed:@"startRecode.png"] forState:UIControlStateNormal];
    }
    else {
        [self.takePhotoBtn setImage:[UIImage imageNamed:@"photoGrayCamera.png"] forState:UIControlStateNormal];
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo {
    NSLog(@"保存视频结果, error = %@", error);
}

- (void)startTimer {
    __weak typeof(self) weakSelf = self;
    self.recodeTime = -1;
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_queue_create(0, 0));
    dispatch_source_set_event_handler(self.timer, ^{
        ++weakSelf.recodeTime;
        dispatch_async(dispatch_get_main_queue(), ^{
             weakSelf.timeLabel.text = [weakSelf timeString];
        });
    });
    dispatch_source_set_timer(self.timer, dispatch_walltime(NULL, 0), (uint64_t)(1 *NSEC_PER_SEC), 0);
    dispatch_resume(self.timer);
}

- (void)stopTimer {
    if (self.timer) {
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
}

- (NSString *)timeString {
    NSInteger second = self.recodeTime % 60;
    NSInteger minuter = (self.recodeTime - self.recodeTime % 60) / 60;
    NSInteger hour = self.recodeTime / 3600;
    return [NSString stringWithFormat:@"%02zd:%02zd:%02zd", hour, minuter, second];
}

@end
