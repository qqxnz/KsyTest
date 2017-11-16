//
//  LiveViewController.m
//  KsyTest
//
//  Created by mm on 2017/8/5.
//  Copyright © 2017年 mm. All rights reserved.
//

#import "LiveViewController.h"
//#import <GPUImage/GPUImage.h>
#import <libksygpulive/KSYGPUStreamerKit.h>


@interface LiveViewController ()
@property (weak, nonatomic) IBOutlet UIButton *stopBtn;
@property (weak, nonatomic) IBOutlet UIButton *meiYanBtn;
@property (weak, nonatomic) IBOutlet UIButton *flashOpenBtn;
@property (weak, nonatomic) IBOutlet UIButton *microphoneOpenBtn;
@property (weak, nonatomic) IBOutlet UIButton *screenShotsBtn;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property NSURL *hostURL;
@property KSYGPUStreamerKit *kit;
@property KSYBeautifyFaceFilter *filter;
@property (nonatomic, assign)   KSYStreamerProfile streamerProfile;
@property (weak, nonatomic) IBOutlet UIButton *switchCameraBtn;

@property bool *meiYanBool;
@property bool *flashBool;
@property bool *microphoneBool;

@end

@implementation LiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.meiYanBool = false;
    self.flashBool = false;
    self.microphoneBool = false;
    
    [self.tableView setBackgroundColor:[UIColor clearColor]];

    [self.switchCameraBtn addTarget:self action:@selector(switchCameraed) forControlEvents:(UIControlEventTouchUpInside)];
    [self.meiYanBtn addTarget:self action:@selector(switchmeiYaned) forControlEvents:(UIControlEventTouchUpInside)];
    [self.stopBtn addTarget:self action:@selector(backView) forControlEvents:(UIControlEventTouchUpInside)];
    [self.flashOpenBtn addTarget:self action:@selector(flashOpened) forControlEvents:(UIControlEventTouchUpInside)];
    [self.screenShotsBtn addTarget:self action:@selector(screenShotsed) forControlEvents:(UIControlEventTouchUpInside)];
    [self.microphoneOpenBtn addTarget:self action:@selector(microphoneOpened) forControlEvents:(UIControlEventTouchUpInside)];
    
    [self startLive];
    //禁止锁屏幕
    [UIApplication sharedApplication].idleTimerDisabled =YES;

}




-(void) startLive{
    
    self.kit = [[KSYGPUStreamerKit alloc] init];
    [self.kit startPreview:self.view];
    
    // 2. 设置采集画面输出方向(手机竖屏, 采集的画面也是竖屏)
    self.kit.vCapDev.outputImageOrientation = UIDeviceOrientationPortrait;
    
    //视频编码器
    self.kit.streamerBase.videoCodec = KSYVideoCodec_X264;
    //音频编码器
    self.kit.streamerBase.audioCodec = KSYAudioCodec_AAC_HE;
    
    //视频码率
    self.kit.streamerBase.videoInitBitrate = 500; // k bit ps
    self.kit.streamerBase.videoMaxBitrate  = 800; // k bit ps
    self.kit.streamerBase.videoMinBitrate  = 0; // k bit ps
    
    //本SDK采用 AAC进行音频编码，faac音频码率推荐为48kbps，at_aac音频码率推荐为64kbps。
    self.kit.streamerBase.audiokBPS = 48;//kbps
    
    //开启码率自适应
    self.kit.streamerBase.bwEstimateMode   = KSYBWEstMode_Default;
    
    //当码率调整时，会有相应的事件通知。详情请查看带宽估计模式 注册通知：
    [[NSNotificationCenter defaultCenter] addObserver:self   selector:@selector(onNetStateEvent:)   name:KSYNetStateEventNotification   object:nil];
    
    //当收到采集状态变化的通知时，通过kit.captureState属性查询新的状态
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(onCaptureStateChange:)  name:KSYCaptureStateDidChangeNotification object:nil];
    
    //当收到推流状态变化的通知时，通过kit.streamerBase.streamState属性查询新的状态
    [[NSNotificationCenter defaultCenter] addObserver:self    selector:@selector(onStreamStateChange:)    name:KSYStreamStateDidChangeNotification object:nil];
    
    NSNotificationCenter *notiftication = [NSNotificationCenter defaultCenter];
    //添加对APP将要暂停运行事件的响应
    [notiftication addObserver:self  selector:@selector(enterBack:) name:UIApplicationDidEnterBackgroundNotification   object:nil];
    //添加对APP重新开始运行事件的响应
    [notiftication addObserver:self  selector:@selector(becameActive:)  name:UIApplicationDidBecomeActiveNotification   object:nil];
    
    // 4. 开启预览
    [self.kit startPreview:self.view];
    
    ////启动推流
    self.hostURL = [[NSURL alloc] initWithString:self.rtmpSrv];
    [self.kit.streamerBase startStream:_hostURL];
    

}


//当码率调整时，会有相应的事件通知。详情请查看带宽估计模式  响应事件：
- (void) onNetStateEvent:(NSNotification *)notification {
    KSYNetStateCode netEvent = _kit.streamerBase.netStateCode;
    if ( netEvent == KSYNetStateCode_SEND_PACKET_SLOW ) {
        NSLog(@"bad network" );
    }
    else if ( netEvent == KSYNetStateCode_EST_BW_RAISE ) {
        NSLog(@"bitrate raising" );
    }
    else if ( netEvent == KSYNetStateCode_EST_BW_DROP ) {
        NSLog(@"bitrate dropping" );
    }
}


//当收到采集状态变化的通知时，通过kit.captureState属性查询新的状态
- (void) onCaptureStateChange:(NSNotification *)notification {
    //设备空闲中
    if ( _kit.captureState == KSYCaptureStateIdle){
        NSLog(@"idle");
    }
    //设备工作中
    else if (_kit.captureState == KSYCaptureStateCapturing ) {
        NSLog(@"capturing");
    }
    //关闭采集设备中
    else if (_kit.captureState == KSYCaptureStateClosingCapture ) {
        NSLog(@"closing capture");
    }
    //设备授权被拒绝
    else if (_kit.captureState == KSYCaptureStateDevAuthDenied ) {
        NSLog(@"camera/mic Authorization Denied");
    }
    //参数错误，无法打开（比如设置的分辨率，码率当前设备不支持）
    else if (_kit.captureState == KSYCaptureStateParameterError ) {
        NSLog(@"capture devices ParameterErro");
    }
    //设备忙碌,稍后尝试
    else if (_kit.captureState == KSYCaptureStateDevBusy ) {
        NSLog(@"device busy, try later");
    }
}


//当收到推流状态变化的通知时，通过kit.streamerBase.streamState属性查询新的状态
- (void) onStreamStateChange:(NSNotification *)notification {
    if ( _kit.streamerBase.streamState == KSYStreamStateIdle) {
        NSLog(@"idle");
        NSLog(@"初始化时状态为空闲");
    }
    else if ( _kit.streamerBase.streamState == KSYStreamStateConnected){
        NSLog(@"connected");
        NSLog(@"KSYStreamStateConnecting");
        
        
    }
    else if (_kit.streamerBase.streamState == KSYStreamStateConnecting ) {
        NSLog(@"kit connecting");
        NSLog(@"KSYStreamStateConnected");
    }
    else if (_kit.streamerBase.streamState == KSYStreamStateDisconnecting ) {
        NSLog(@"disconnecting");
        NSLog(@"KSYStreamStateDisconnecting");
    }
    else if (_kit.streamerBase.streamState == KSYStreamStateError ) {
        NSLog(@"KSYStreamStateError");
        [self onStreamError:KSYStreamStateError];
    }
}
///推流错误处理
- (void) onStreamError:(KSYStreamErrorCode) errCode{
    NSLog(@"%@",[_kit.streamerBase getCurKSYStreamErrorCodeName]);
    if (errCode == KSYStreamErrorCode_CONNECT_BREAK) {
        // Reconnect
        [self tryReconnect];
    }
    else if (errCode == KSYStreamErrorCode_AV_SYNC_ERROR) {
        NSLog(@"audio video is not synced, please check timestamp");
        [self tryReconnect];
    }
    else if (errCode == KSYStreamErrorCode_CODEC_OPEN_FAILED) {
        NSLog(@"video codec open failed, try software codec");
        _kit.streamerBase.videoCodec = KSYVideoCodec_X264;
        [self tryReconnect];
    }
}
//重连操作
- (void) tryReconnect {
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC));
    dispatch_after(delay, dispatch_get_main_queue(), ^{
        NSLog(@"try again");
        _kit.streamerBase.bWithVideo = YES;
        [_kit.streamerBase startStream:self.hostURL];

    });
}



///前后摄像头切换
-(void)switchCameraed{
//    self.kit.cameraPosition = AVCaptureDevicePositionBack;//（前置／后置）
    [self.kit switchCamera];
}

///美颜开关
-(void)switchmeiYaned{
    
    if(self.meiYanBool == false){
        //初始化美颜滤镜
        _filter = [[KSYBeautifyFaceFilter alloc] init];
        
        [_kit setupFilter: _filter];
        self.meiYanBool = true;
    }else{
        _filter = nil;
        [_kit setupFilter: _filter];//取消滤镜只要将_filter置为nil就行
        self.meiYanBool = false;
    }
    

}



//APP将要暂停运行：
- (void) enterBack:(NSNotification *)not{
//    [_kit appEnterBackground:NO];
    [_kit appEnterBackground];
}


//APP重新开始运行
- (void) becameActive:(NSNotification *)not{
    [_kit appBecomeActive];
}

//麦克风开关
-(void)microphoneOpened{
    
    if(self.microphoneBool == false){
        [self.kit.streamerBase muteStream:YES];
        self.microphoneBool = true;
    }else{
        [self.kit.streamerBase muteStream:NO];
        self.microphoneBool = false;
    }
    
    
}

//退出页面停止推流
-(void)backView{
    
    ///停止推流
    [self.kit.streamerBase stopStream];
    
    ////停止采集
    [self.kit stopPreview];
    
    self.kit = nil;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}


///闪光灯开关
-(void)flashOpened{
    if(self.kit.cameraPosition != AVCaptureDevicePositionBack){
        NSLog(@"不是后摄像头");
        return;
    }
    
    if (self.flashBool == false) { //打开闪光灯
        AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        NSError *error = nil;
        
        if ([captureDevice hasTorch]) {
            BOOL locked = [captureDevice lockForConfiguration:&error];
            if (locked) {
                captureDevice.torchMode = AVCaptureTorchModeOn;
                [captureDevice unlockForConfiguration];
                self.flashBool = true;
            }
        }
    }else{//关闭闪光灯
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch]) {
            [device lockForConfiguration:nil];
            [device setTorchMode: AVCaptureTorchModeOff];
            [device unlockForConfiguration];
            self.flashBool = false;
        }
    }
    
}

//屏幕截图
-(void)screenShotsed{
    
    CGRect rect = [[UIScreen mainScreen] bounds];

    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
    
    
    [self.view drawViewHierarchyInRect:rect afterScreenUpdates:NO];
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    UIImageWriteToSavedPhotosAlbum(img, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    
    
}

//保存图片
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo

{
    
    NSString *msg = nil;
    
    if(error != NULL){
        
        msg = @"保存图片失败";
        
        
    }else{
        
        msg = @"保存图片成功";
        
    }
    
    NSLog(@"%@", msg);

}



-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:YES];
    //当码率调整时
    [[NSNotificationCenter defaultCenter] removeObserver:self  name:KSYNetStateEventNotification  object:nil];
    //当收到采集状态变化的通知时
    [[NSNotificationCenter defaultCenter] removeObserver:self  name:KSYCaptureStateDidChangeNotification   object:nil];
    //当收到推流状态变化的通知时，通过kit.streamerBase.streamState属性查询新的状态
    [[NSNotificationCenter defaultCenter] removeObserver:self   name:KSYStreamStateDidChangeNotification  object:nil];
    ///前后台通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //取消禁止锁屏
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
