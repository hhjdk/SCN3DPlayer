//
//  HelloViewController.m
//  SCN3DPlayer
//
//  Created by 俞涛涛 on 16/11/11.
//  Copyright © 2016年 俞涛涛. All rights reserved.
//

#import "HelloViewController.h"
#import "SCN3DPlayerView.h"
#import "SCN3DVideoAdatper.h"
#import "HelloViewController.h"
#import "Masonry.h"

@interface HelloViewController ()<SCN3DVideoAdatperDelegate>{
    

}
@property (nonatomic,strong)SCN3DPlayerView *scn3DPlayerView;
@property (nonatomic,strong)SCN3DVideoAdatper *scn3dVideo;
//@property (strong, nonatomic) IBOutlet UIButton *playAndStop;
//@property (strong, nonatomic) IBOutlet UILabel *curTimeLabel;
//@property (strong, nonatomic) IBOutlet UILabel *allTimeLabel;
//@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
//@property (strong, nonatomic) IBOutlet UISlider *timeSlider;
//@property (strong, nonatomic) IBOutlet UIView *upView;
//@property (strong, nonatomic) IBOutlet UIView *videoView;

@property (strong, nonatomic)  UIButton *playAndStop;
@property (strong, nonatomic)  UILabel *curTimeLabel;
@property (strong, nonatomic)  UILabel *allTimeLabel;
@property (strong, nonatomic)  UIProgressView *progressView;
@property (strong, nonatomic)  UISlider *timeSlider;
@property (strong, nonatomic)  UIView *upView;
@property (strong, nonatomic)  UIView *videoView;

@property (nonatomic, assign) CGSize displaySize;
@property (nonatomic, assign) float aspect;

@end


@implementation HelloViewController

-(void)viewWillDisappear:(BOOL)animated{
    [self.scn3dVideo pause];
    [self.scn3dVideo removeDisplaylink];
    [self.scn3DPlayerView removeFromSuperview];
     self.scn3DPlayerView = nil;

}

-(void)viewWillAppear:(BOOL)animated{
//    self.scn3DPlayerView.frame = self.videoView.bounds;

}
-(void)viewDidAppear:(BOOL)animated{
    self.scn3DPlayerView.frame = self.view.frame;
    

    


}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view, typically from a nib.

    [self initSCN3DPlayerView];
    [self setSlider];
    [self initBtn];
    [self initVideo];
    
    
    }

-(void)initSCN3DPlayerView{
     self.scn3DPlayerView  = [[SCN3DPlayerView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:self.scn3DPlayerView];
    [self.scn3DPlayerView  setInteractiveMode:SCN3DInteractive_MotionAndTouch];//设置重力触摸模式
//    [self.scn3DPlayerView setVideoAspectRatio:2.0];//设置视频宽高比
    [self.scn3DPlayerView setVideoDisplayMode:SCN3DDisplayMode_Plane_Normal];//初始化设置普通模式
    [self.scn3DPlayerView setHorizontalEnabled:YES verticalEnabled:YES];//设置触摸开关
    [self.scn3DPlayerView setPinchScaleEnabled:YES];//设置允许缩放
    [self.scn3DPlayerView setMinScale:1 maxScale:2.0];//设置缩放比例范围
    [self.scn3DPlayerView setCurrentScale:1.0]; //设置当前缩放比例


}
-(void)setSlider{
    _upView = [[UIView alloc]init];
    [self.view addSubview:_upView];
    _upView.backgroundColor = [UIColor grayColor];
    
    _playAndStop = [[UIButton alloc]init];
    
    [self.upView addSubview:_playAndStop];
    [_playAndStop setImage:[UIImage imageNamed:@"play_nor"] forState:UIControlStateNormal];
    [_playAndStop setImage:[UIImage imageNamed:@"pause_nor"] forState:UIControlStateSelected];
    [_playAndStop addTarget:self action:@selector(playAndstopClick:) forControlEvents:UIControlEventTouchUpInside];
    
    _curTimeLabel =[[UILabel alloc]init];
    [self.upView addSubview:_curTimeLabel];
    _curTimeLabel.text = @"00:00:00";
    _curTimeLabel.font =[UIFont systemFontOfSize:13];
    
    _allTimeLabel = [[UILabel alloc]init];
    [self.upView addSubview:_allTimeLabel];
    _allTimeLabel.text = @"00:00:00";
    _allTimeLabel.font = [UIFont systemFontOfSize:13];
    
    _progressView = [[UIProgressView alloc]init];
    [self.upView addSubview:_progressView];
    _progressView.progress = 0.0 ;
    
    _timeSlider = [[UISlider alloc]init];
    [self.upView addSubview:_timeSlider];
    _timeSlider.value = 0;
    [_timeSlider addTarget:self action:@selector(timeSliderValueChanged:) forControlEvents: UIControlEventValueChanged];
 
    
    
    __weak typeof(self) weakSelf = self;
    
    [self.upView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.and.trailing.equalTo(weakSelf.view).offset(0);
        make.bottom.equalTo(weakSelf.view).offset(0);
        make.height.equalTo(@60);
    }];
    
    [self.playAndStop mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakSelf.upView);
        make.centerY.equalTo(weakSelf.upView);
        make.height.and.width.equalTo(@40);

    }];
    
    [self.curTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakSelf.playAndStop.mas_trailing).offset(0);
        make.centerY.equalTo(weakSelf.upView);
        make.width.equalTo (@60);
        
    }];
    [self.allTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(weakSelf.upView.mas_trailing).offset(-5);
        make.centerY.equalTo(weakSelf.upView);
        make.width.equalTo (@60);
        
    }];
    
    [self.timeSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakSelf.curTimeLabel.mas_trailing).offset(0);
        make.trailing.equalTo(weakSelf.allTimeLabel.mas_leading).offset(-8);
        make.centerY.equalTo(weakSelf.upView);
    }];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakSelf.curTimeLabel.mas_trailing).offset(0);
        make.trailing.equalTo(weakSelf.allTimeLabel.mas_leading).offset(-8);
        make.centerY.equalTo(weakSelf.upView);
    }];
    
    
    
    
    
    [self.timeSlider setThumbImage:[UIImage imageNamed:@"ic_circle@2x"] forState:UIControlStateNormal];
    [self.timeSlider setThumbImage:[UIImage imageNamed:@"ic_circle@2x"] forState:UIControlStateHighlighted];
    UIGraphicsBeginImageContextWithOptions((CGSize){ 1, 1 }, NO, 0.0f);
    UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.timeSlider setMinimumTrackImage:transparentImage forState:UIControlStateNormal];
    [self.timeSlider setMaximumTrackImage:transparentImage forState:UIControlStateNormal];
}

-(void)initBtn{
    UIButton * btn0 = [[UIButton alloc]initWithFrame:CGRectMake(100, 50, 70, 40)];
    [btn0 setTitle:@"正常" forState:UIControlStateNormal];
    [btn0 setBackgroundColor:[UIColor blueColor]];
    [self.view addSubview: btn0];
     btn0.alpha = 0.5;
     btn0.tag = SCN3DDisplayMode_Plane_Normal;
    [btn0 addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
    
    UIButton * btn = [[UIButton alloc]initWithFrame:CGRectMake(100, 100, 70, 40)];
    [btn setTitle:@"平面180" forState:UIControlStateNormal];
    [btn setBackgroundColor:[UIColor blueColor]];
    [self.view addSubview: btn];
     btn.alpha = 0.5;
     btn.tag = SCN3DDisplayMode_Plane_Slide;
    [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
    
    UIButton * btn2 = [[UIButton alloc]initWithFrame:CGRectMake(100, 150, 70, 40)];
    [btn2 setTitle:@"圆柱" forState:UIControlStateNormal];
    [btn2 setBackgroundColor:[UIColor blueColor]];
    [self.view addSubview: btn2];
     btn2.alpha = 0.5;
     btn2.tag = SCN3DDisplayMode_Tube;
    [btn2 addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
    
    UIButton * btn3 = [[UIButton alloc]initWithFrame:CGRectMake(100, 200, 70, 40)];
    [btn3 setTitle:@"圆" forState:UIControlStateNormal];
    [btn3 setBackgroundColor:[UIColor blueColor]];
    [self.view addSubview: btn3];
    btn3.alpha = 0.5;
    btn3.tag = SCN3DDisplayMode_Sphere;
    [btn3 addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIButton * btn4 = [[UIButton alloc]initWithFrame:CGRectMake(100, 250, 70, 40)];
    [btn4 setTitle:@"全景" forState:UIControlStateNormal];
    [btn4 setBackgroundColor:[UIColor blueColor]];
    [self.view addSubview: btn4];
    btn4.alpha = 0.5;
    btn4.tag = SCN3DDisplayMode_VR360;
    [btn4 addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIButton * btn5 = [[UIButton alloc]initWithFrame:CGRectMake(100, 300, 70, 40)];
    [btn5 setTitle:@"VR" forState:UIControlStateNormal];
    [btn5 setBackgroundColor:[UIColor blueColor]];
    [self.view addSubview: btn5];
    btn5.alpha = 0.5;
    btn5.tag = SCN3DDisplayMode_VRGlass;
    [btn5 addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
    
    UIButton * btn6 = [[UIButton alloc]initWithFrame:CGRectMake(10, 10, 50, 50)];
    [btn6 setTitle:@"返回" forState:UIControlStateNormal];
    [btn6 setBackgroundColor:[UIColor blueColor]];
    [self.view addSubview: btn6];
    btn6.alpha = 0.5;
    [btn6 addTarget:self action:@selector(backClick:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton * btn7 = [[UIButton alloc]initWithFrame:CGRectMake(80, 10, 50, 50)];
    [btn7 setTitle:@"+" forState:UIControlStateNormal];
    [btn7 setBackgroundColor:[UIColor blueColor]];
    [self.view addSubview: btn7];
    btn7.alpha = 0.5;
    [btn7 addTarget:self action:@selector(addvoluem:) forControlEvents:UIControlEventTouchUpInside];
    UIButton * btn8 = [[UIButton alloc]initWithFrame:CGRectMake(150, 10, 50, 50)];
    [btn8 setTitle:@"-" forState:UIControlStateNormal];
    [btn8 setBackgroundColor:[UIColor blueColor]];
    [self.view addSubview: btn8];
    btn8.alpha = 0.5;
    
    [btn8 addTarget:self action:@selector(subvoluem:) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapClick)];
    [self.view addGestureRecognizer:tap];
   

}

-(void)btnClick:(UIButton*)btn{
    
    if (btn.tag == SCN3DDisplayMode_Plane_Normal) {
        [self.scn3DPlayerView setVideoDisplayMode:SCN3DDisplayMode_Plane_Normal];
        
    }else if (btn.tag == SCN3DDisplayMode_Plane_Slide) {
        [self.scn3DPlayerView setVideoDisplayMode:SCN3DDisplayMode_Plane_Slide];
        [self.scn3DPlayerView setHorizontalEnabled:YES verticalEnabled:NO];//设置水平垂直是否启用
        [self.scn3DPlayerView setPinchScaleEnabled:YES];



    }else if (btn.tag == SCN3DDisplayMode_Tube){
        [self.scn3DPlayerView setVideoDisplayMode:SCN3DDisplayMode_Tube];
        [self.scn3DPlayerView setHorizontalEnabled:YES verticalEnabled:YES];
        [self.scn3DPlayerView setVerticalMinRotate:-60 maxRotate:60];


    }else if (btn.tag == SCN3DDisplayMode_Sphere){
        [self.scn3DPlayerView setVideoDisplayMode:SCN3DDisplayMode_Sphere];
        [self.scn3DPlayerView setHorizontalEnabled:YES verticalEnabled:YES];//设置水平垂直是否启用

    }else if (btn.tag == SCN3DDisplayMode_VR360){
        
        [self.scn3DPlayerView setVideoDisplayMode:SCN3DDisplayMode_VR360];
        [self.scn3DPlayerView setVerticalMinRotate:30 maxRotate:90];
        [self.scn3DPlayerView setCurrentRotateX:30 rotateY:0];
         self.scn3DPlayerView.cameraNode.position = SCNVector3Make(0, 0.1, 1.0);
        [self.scn3DPlayerView setHorizontalEnabled:YES verticalEnabled:YES];
        [self.scn3DPlayerView setGSensorMotionEnabled:YES];
        [self.scn3DPlayerView setPinchScaleEnabled:YES];

        
    }else if (btn.tag == SCN3DDisplayMode_VRGlass){
        
        [self.scn3DPlayerView setVideoDisplayMode:SCN3DDisplayMode_VRGlass];
        [self.scn3DPlayerView setHorizontalEnabled:YES verticalEnabled:YES];
        [self.scn3DPlayerView setGSensorMotionEnabled:YES];
        [self.scn3DPlayerView setPinchScaleEnabled:YES];

    }


}

-(void)tapClick{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            self.upView.alpha = 1.0;
            self.upView.alpha = 1.0;
        }];
        
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:1.0 animations:^{
            self.upView.alpha = 0.0;
            self.upView.alpha = 0.0;
        }];
        
    });



}
-(void)initVideo{
    self.scn3dVideo = [[SCN3DVideoAdatper alloc]init];
        
    NSString * urlString = [[NSBundle mainBundle]pathForResource:@"abc" ofType:@"mp4"];
//    NSString * urlString = @"http://cache.utovr.com/aa38e1ffef5d4b9baaf393777dbc9342/L2_gx91akbix0qkiacw.mp4";
    
    
    NSURL *videoURL;
    
    if ([self checkPathIsHTTPURL:urlString]) {
        videoURL = [NSURL URLWithString:urlString]; //网络视频

    }
    else {
        videoURL = [NSURL fileURLWithPath:urlString];//本地视频

    }
    //播放方法一
    [self.scn3dVideo setURL:videoURL];
    
    //播放方法二
//    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:url];
//    [self.scn3dVideo setPlayerItem:playerItem];
    
    //方法三
//    AVAsset * asset = [AVAsset assetWithURL:url];
//    [self.scn3dVideo setAsset:asset];
    
    
     self.scn3dVideo.delegate = self;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}
    
    
    
    
    
- (void)videoPlayerIsReadyToPlayVideo:(SCN3DVideoAdatper *)videoAdatper{
    NSLog(@"准备播放====================");
    [self.scn3dVideo addDisplaylink];
    [self.scn3dVideo play];
     self.playAndStop.selected = YES;
    int totalTime = CMTimeGetSeconds(videoAdatper.playerItem.duration);
    self.timeSlider.maximumValue = totalTime;
    self.allTimeLabel.text = [self getVideoTimeString:totalTime];
    NSLog(@"time =========%d",totalTime);

}

- (void)videoPlayerDidReachEnd:(SCN3DVideoAdatper *)videoAdatper{
    NSLog(@"播放结束 ==============");
    [self.scn3dVideo pause];
   
        
}

- (void)videoPlayer:(SCN3DVideoAdatper *)videoAdatper timeDidChange:(CMTime)cmTime{
   
    int curTime = CMTimeGetSeconds(cmTime);
    self.timeSlider.value = curTime;
    self.curTimeLabel.text = [self getVideoTimeString:curTime];
}

- (void)videoPlayer:(SCN3DVideoAdatper *)videoAdatper loadedTimeRangeDidChange:(float)duration{
    
    // 视频缓冲长度
    int totalTime = CMTimeGetSeconds(videoAdatper.playerItem.duration);
    if (totalTime != 0) {
        self.progressView.progress = duration / totalTime;

    
    }
}
- (void)videoPlayer:(SCN3DVideoAdatper *)videoAdatper didFailWithError:(NSError *)error{
    NSLog(@"error====================%@",error);
}
    
- (void)videoPlayer:(SCN3DVideoAdatper *)videoAdatper displaylinkCallbackImage:(UIImage *)videoImage{
    //获取视频的每一帧
    [self.scn3DPlayerView setFramesPerVideoImage:videoImage];
    _aspect = videoImage.size.width/videoImage.size.height;
    
        
}

- (NSString *)getVideoTimeString:(int)time {
    int hou = time / 3600;
    int min = (time - hou * 60) / 60;
    int sec = time - hou * 3600 - min * 60;
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hou, min, sec];
}

//支持的方向
-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
        
    return UIInterfaceOrientationMaskAll;
        
}
    
//是否可以旋转
-(BOOL)shouldAutorotate{
    
    return YES;
}
// 横竖屏适配.
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    
    [self relayout];
}
    
- (void)relayout
{
    if(self.view.frame.size.width>self.view.frame.size.height) {
        self.scn3DPlayerView .frame = self.view.frame;
            
    } else {
        self.scn3DPlayerView.frame = self.view.frame;
    }
}

- (BOOL)checkPathIsHTTPURL:(NSString *)path {
    NSString *head = [path substringWithRange:NSMakeRange(0, 4)];
    NSStringCompareOptions options = NSCaseInsensitiveSearch | NSNumericSearch;
    if ([head compare:@"http" options:options] == NSOrderedSame) {
        return YES;
    }
    return NO;
}
- (void)playAndstopClick:(UIButton *)sender {
    if (self.scn3dVideo.isPlaying) {
        [self.scn3dVideo pause];
        self.playAndStop.selected = NO;
    }else{
        [self.scn3dVideo play];
        self.playAndStop.selected = YES;
    }
}

- (void)timeSliderValueChanged:(UISlider*)sender {  // 滑动播放进度
    float seekTime = sender.value;
    if (self.scn3dVideo.isPlaying) {
        [self.scn3dVideo pause];
    }
    if (self.playAndStop.selected == YES) {
        [self.scn3dVideo play];
    }

    [self.scn3dVideo seekToTime:seekTime completion:nil];
}
- (void)backClick:(UIButton *)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)subvoluem:(UIButton *)sender{
    
    [self.scn3dVideo fadeOutVolume];
}
-(void)addvoluem:(UIButton *)sender{
    
    [self.scn3dVideo  fadeInVolume];
}

@end
