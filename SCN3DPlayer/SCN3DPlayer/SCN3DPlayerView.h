//
//  SCN3DPlayerView.h
//  SCN3DPlayer
//
//  Created by 俞涛涛 on 16/11/11.
//  Copyright © 2016年 俞涛涛. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import <GLKit/GLKit.h>


/////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 触摸，重力，触摸重力

 - SCN3DInteractive_Touch: 触摸
 - SCN3DInteractive_Motion: 重力
 - SCN3DInteractive_MotionAndTouch: 触摸和重力
 */
typedef NS_ENUM(NSInteger, SCN3DInteractive_) {
    SCN3DInteractive_Touch,
    SCN3DInteractive_Motion,
    SCN3DInteractive_MotionAndTouch,
};

/**
 形状模式枚举

 - SCN3DDisplayMode_Plane_Normal: 普通模式
 - SCN3DDisplayMode_Plane_Slide: 平面180模式
 - SCN3DDisplayMode_Tube: 圆柱模式
 - SCN3DDisplayMode_Sphere: 球模式
 - SCN3DDisplayMode_VR360: 全景模式
 - SCN3DDisplayMode_VRGlass: VR双屏模式
 */
typedef NS_ENUM(NSUInteger, SCN3DDisplayMode_) {
    SCN3DDisplayMode_Plane_Normal = 0,
    SCN3DDisplayMode_Plane_Slide,
    SCN3DDisplayMode_Tube,
    SCN3DDisplayMode_Sphere,
    SCN3DDisplayMode_VR360,
    SCN3DDisplayMode_VRGlass,
};

/////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface SCN3DPlayerView : UIView

@property (nonatomic, strong) SCNScene *scene;
@property (nonatomic, strong) SCNView  *scViewLeft;
@property (nonatomic, strong) SCNView  *scViewRight;
@property (nonatomic, strong) SCNNode  *shapeNode;
@property (nonatomic, strong) SCNNode  *cameraNode;

//_________________________________________________________________________________________________

/**
 设置使用重力，还是手指触摸，或者两者都持

 @param interactive SCN3DInteractive_ 枚举参数
 */
- (void)setInteractiveMode:(SCN3DInteractive_)interactive;

/**
 设置sceneKit 渲染模式，有Vr ，全景，等等模式

 @param displayMode SCN3DDisplayMode_ 枚举参数
 */
- (void)setVideoDisplayMode:(SCN3DDisplayMode_)displayMode;

/**
 是否，水平启用，垂直启用

 @param horEnabled Yes or no
 @param verEnabled yes or no
 */
- (void)setHorizontalEnabled:(BOOL)horEnabled verticalEnabled:(BOOL)verEnabled;

//是否开启重力传感器
- (void)setGSensorMotionEnabled:(BOOL)GSensorEnabled;
//是否开启缩放功能
- (void)setPinchScaleEnabled:(BOOL)pinchEnabled;
//设置缩放范围
- (void)setMinScale:(float)minScale maxScale:(float)maxScale;
//设置旋转范围
- (void)setVerticalMinRotate:(float)minRotate maxRotate:(float)maxRotate;
//设置纹理坐标平移
- (void)setTextureOffsetX:(float)x offsetY:(float)y;
//设置纹理坐标缩放
- (void)setTextureScaleX:(float)x ScaleY:(float)y;

//_________________________________________________________________________________________________
//设置宽高比
- (void)setVideoAspectRatio:(float)aspectRatio;
//设置当前横屏或者竖屏
- (void)setCurrentOrientation:(UIInterfaceOrientation)orientation;
//设置当前缩放比例
- (void)setCurrentScale:(float)curScale;
//设置当前旋转角度
- (void)setCurrentRotateX:(float)rotateX rotateY:(float)rotateY;

//_________________________________________________________________________________________________
//设置帧视频图像
- (void)setFramesPerVideoImage:(UIImage *)image;

@end
