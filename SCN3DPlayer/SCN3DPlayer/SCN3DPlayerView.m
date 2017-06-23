//
//  SCN3DPlayerView.m
//  SCN3DPlayer
//
//  Created by 俞涛涛 on 16/11/11.
//  Copyright © 2016年 俞涛涛. All rights reserved.
//

#import "SCN3DPlayerView.h"
#import <CoreMotion/CoreMotion.h>

@interface SCN3DPlayerView ()

@property (nonatomic, assign) float rotateX;
@property (nonatomic, assign) float rotateY;
@property (nonatomic, assign) float minRotateX;
@property (nonatomic, assign) float maxRotateX;
@property (nonatomic, assign) float minScale;
@property (nonatomic, assign) float maxScale;
@property (nonatomic, assign) float curScale;
@property (nonatomic, assign) float prevScale;
@property (nonatomic, assign) float videoAspRatio;
@property (nonatomic, assign) BOOL  pinchEnabled;
@property (nonatomic, assign) BOOL  horizontalEnabled;
@property (nonatomic, assign) BOOL  verticalEnabled;
@property (nonatomic, assign) BOOL  GSensorEnabled;
@property (nonatomic, assign) SCN3DInteractive_ interactive;
@property (nonatomic, assign) SCN3DDisplayMode_ displayMode;
@property (nonatomic, assign) SCNMatrix4 modelMatrix;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) UIInterfaceOrientation orientation;

@end

@implementation SCN3DPlayerView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initScene];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    if (self.displayMode == SCN3DDisplayMode_VRGlass) {
        self.scViewLeft.frame  = CGRectMake(0, 0, self.frame.size.width / 2, self.frame.size.height);
        self.scViewRight.frame = CGRectMake(self.frame.size.width / 2, 0, self.frame.size.width / 2, self.frame.size.height);
    }
    else {
        self.scViewLeft.frame  = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    self.scViewLeft.backgroundColor  = backgroundColor;
    self.scViewRight.backgroundColor = backgroundColor;
}

- (void)initScene {
    self.scene  = [SCNScene scene];
    self.scViewLeft = [[SCNView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) options:nil];
    self.scViewLeft.backgroundColor = [UIColor blackColor];
    self.scViewLeft.scene = self.scene;
    self.scViewLeft.antialiasingMode = SCNAntialiasingModeMultisampling4X;
    [self addSubview:self.scViewLeft];
    
    self.cameraNode = [SCNNode node];
    self.cameraNode.camera = [SCNCamera camera];
    [self.scene.rootNode addChildNode:self.cameraNode];
    
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchScale:)];
    [self addGestureRecognizer:pinchGestureRecognizer];
}

- (void)initSceneNodeWithMode:(SCN3DDisplayMode_)displayMode {
    [self.shapeNode   removeFromParentNode];
    [self.scViewRight removeFromSuperview];
    [self initParameterSetting];
    switch (displayMode) {
        case SCN3DDisplayMode_Plane_Normal: {
            float width  = 2.0;
            float height = width / self.videoAspRatio;
            self.shapeNode = [SCNNode nodeWithGeometry:[SCNPlane planeWithWidth:width height:height]];
            self.shapeNode.geometry.firstMaterial.diffuse.wrapT = SCNWrapModeClamp;
            self.shapeNode.geometry.firstMaterial.diffuse.wrapS = SCNWrapModeClamp;
            self.shapeNode.geometry.firstMaterial.cullMode = SCNCullBack;
            self.cameraNode.position = SCNVector3Make(0, 0, 1.5);
            self.cameraNode.camera.usesOrthographicProjection = YES;
        }
            break;
        case SCN3DDisplayMode_Plane_Slide: {
            float width  = 2.0;
            float height = width / self.videoAspRatio;
            self.shapeNode = [SCNNode nodeWithGeometry:[SCNPlane planeWithWidth:width height:height]];
            self.shapeNode.geometry.firstMaterial.diffuse.wrapT = SCNWrapModeRepeat;
            self.shapeNode.geometry.firstMaterial.diffuse.wrapS = SCNWrapModeRepeat;
            self.shapeNode.geometry.firstMaterial.cullMode = SCNCullBack;
            self.cameraNode.position = SCNVector3Make(0, 0, 1.5);
            self.cameraNode.camera.usesOrthographicProjection = YES;
            
        }
            break;
        case SCN3DDisplayMode_Tube: {
            SCNTube *tube = [SCNTube tubeWithInnerRadius:1.0 outerRadius:1.0 height:1.0];
            tube.radialSegmentCount = 96;
            self.shapeNode = [SCNNode nodeWithGeometry:tube];
            self.shapeNode.geometry.firstMaterial.diffuse.wrapT = SCNWrapModeClamp;
            self.shapeNode.geometry.firstMaterial.diffuse.wrapS = SCNWrapModeClamp;
            self.shapeNode.geometry.firstMaterial.cullMode = SCNCullBack;
            
            self.cameraNode.position = SCNVector3Make(0, 0, 1.5);
            self.cameraNode.camera.usesOrthographicProjection = YES;
        }
            break;
        case SCN3DDisplayMode_Sphere: {
            
            SCNSphere *sphere = [SCNSphere sphereWithRadius:1.0];
            sphere.segmentCount = 96;
            self.shapeNode = [SCNNode nodeWithGeometry:sphere];
            self.shapeNode.geometry.firstMaterial.diffuse.wrapT = SCNWrapModeClamp;
            self.shapeNode.geometry.firstMaterial.diffuse.wrapS = SCNWrapModeClamp;
            self.shapeNode.geometry.firstMaterial.cullMode = SCNCullBack;// 设置剔除内表面
            self.cameraNode.position = SCNVector3Make(0, 0, 1.5);
            self.cameraNode.camera.usesOrthographicProjection = YES;
        }
            break;
        case SCN3DDisplayMode_VR360: {
  
            SCNSphere *sphere = [SCNSphere sphereWithRadius:1.0];
            sphere.segmentCount = 96;
            self.shapeNode = [SCNNode nodeWithGeometry:sphere];
            self.shapeNode.geometry.firstMaterial.diffuse.wrapT = SCNWrapModeClamp;
            self.shapeNode.geometry.firstMaterial.diffuse.wrapS = SCNWrapModeClamp;
            self.shapeNode.geometry.firstMaterial.cullMode = SCNCullFront;
            self.shapeNode.geometry.firstMaterial.doubleSided = false; // 设置只渲染一个表面
            self.cameraNode.position = SCNVector3Make(0, 0, 1.5);
            self.cameraNode.camera.usesOrthographicProjection = NO;
            
//            SCNMatrix4 contentsTransform = self.shapeNode.geometry.firstMaterial.diffuse.contentsTransform;
////            SCNMatrix4 contentsTransform2 = self.shapeNode.transform;
//       
//            contentsTransform =SCNMatrix4Rotate(contentsTransform, 0, M_PI, 0, 0);
//            self.shapeNode.transform = self.shapeNode.geometry.firstMaterial.diffuse.contentsTransform;
     
            
 
        }
            break;
        case SCN3DDisplayMode_VRGlass: {
            SCNSphere *sphere = [SCNSphere sphereWithRadius:1.0];
            sphere.segmentCount = 96;
            self.shapeNode = [SCNNode nodeWithGeometry:sphere];
            self.shapeNode.geometry.firstMaterial.diffuse.wrapT = SCNWrapModeClamp;
            self.shapeNode.geometry.firstMaterial.diffuse.wrapS = SCNWrapModeClamp;
            self.shapeNode.geometry.firstMaterial.cullMode = SCNCullFront;// 设置剔除外表面
            self.shapeNode.geometry.firstMaterial.doubleSided = false; // 设置只渲染一个表面
//            self.cameraNode.position = SCNVector3Make(0, 0, 1.5);
            self.cameraNode.camera.usesOrthographicProjection = NO;
            
            self.scViewLeft.frame  = CGRectMake(0, 0, self.frame.size.width / 2, self.frame.size.height);
            self.scViewRight = [[SCNView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2, 0, self.frame.size.width / 2, self.frame.size.height) options:nil];
            self.scViewRight.backgroundColor = [UIColor blackColor];
            self.scViewRight.scene = self.scene;
            self.scViewRight.antialiasingMode = SCNAntialiasingModeMultisampling4X;
            [self addSubview:self.scViewRight];
        }
            break;
            
        default:
            break;
    }
    
    self.cameraNode.camera.zNear = 0.01f;
    self.cameraNode.camera.zFar  = 100.0f;
    self.shapeNode.castsShadow = NO;
    self.shapeNode.position = SCNVector3Make(0, 0, 0);
    [self.scene.rootNode addChildNode:self.shapeNode];
    
    self.modelMatrix = self.shapeNode.transform;
    [self setCurrentScale:1.0];
    [self setFramesPerVideoImage:nil];
}

- (void)initParameterSetting {
    self.rotateX    = 0.0;
    self.rotateY    = 0.0;
    self.minRotateX = - M_PI / 2;
    self.maxRotateX = + M_PI / 2;
    self.minScale   = 1.0;
    self.maxScale   = 2.0;
    self.curScale   = 1.0;
    self.prevScale  = self.curScale;
    self.videoAspectRatio = 2.0 / 1.0;
    self.scViewLeft.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    self.scViewRight = nil;
    
    self.horizontalEnabled = NO;
    self.verticalEnabled = NO;
    self.GSensorEnabled = NO;
    self.pinchEnabled = NO;
    [self stopGSENSORMotion];
}

- (void)dealloc {
    
    [self.shapeNode removeFromParentNode];
    [self.cameraNode removeFromParentNode];
    self.scViewLeft  = nil;
    self.scViewRight = nil;
    [self stopGSENSORMotion];
    NSLog(@"=============sceneKit dealloc=======");
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark SCN3DPlayerSetting
/////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setInteractiveMode:(SCN3DInteractive_)interactive {
    self.interactive = interactive;
}

- (void)setVideoDisplayMode:(SCN3DDisplayMode_)displayMode {
    self.displayMode = displayMode;
    [self initSceneNodeWithMode:displayMode];
}

- (void)setHorizontalEnabled:(BOOL)horEnabled verticalEnabled:(BOOL)verEnabled {
    self.horizontalEnabled = horEnabled;
    self.verticalEnabled   = verEnabled;
}

- (void)setGSensorMotionEnabled:(BOOL)GSensorEnabled {
    self.GSensorEnabled = GSensorEnabled;
    if (GSensorEnabled) {
        [self startGSENSORMotion];
    }
    else {
        [self stopGSENSORMotion];
    }
}

- (void)setPinchScaleEnabled:(BOOL)pinchEnabled {
    self.pinchEnabled = pinchEnabled;
}

- (void)setVideoAspectRatio:(float)aspectRatio {
    self.videoAspRatio = aspectRatio;
}

- (void)setCurrentOrientation:(UIInterfaceOrientation)orientation {
    self.orientation = orientation;
    switch (self.displayMode) {
        case SCN3DDisplayMode_Plane_Normal:
        case SCN3DDisplayMode_Plane_Slide: {
            SCNPlane *plane = (SCNPlane *)self.shapeNode.geometry;
            float perPixel, videoWidth, videoHeight;
            
            // 根据当前视图大小和视频宽高比来适配视频显示的宽高
            if (orientation == UIDeviceOrientationPortrait) {
                perPixel    = 2.0 / self.scViewLeft.frame.size.width;
                videoWidth  = self.scViewLeft.frame.size.width;
                videoHeight = videoWidth / self.videoAspRatio;
                
                if (videoHeight > self.scViewLeft.frame.size.height) {
                    videoHeight = self.scViewLeft.frame.size.height;
                    videoWidth  = videoHeight * self.videoAspRatio;
                }
                plane.width  = videoWidth * perPixel;
                plane.height = videoHeight * perPixel;
            }
            else {
                perPixel    = 2.0 / self.scViewLeft.frame.size.height;
                videoHeight = self.scViewLeft.frame.size.height;
                videoWidth  = videoHeight * self.videoAspRatio;
                
                if (videoWidth > self.scViewLeft.frame.size.width) {
                    videoWidth  = self.scViewLeft.frame.size.width;
                    videoHeight = videoWidth / self.videoAspRatio;
                }
                plane.width  = videoWidth * perPixel;
                plane.height = videoHeight * perPixel;
            }
        }
            break;
        case SCN3DDisplayMode_Tube: {
        }
            break;
        case SCN3DDisplayMode_Sphere: {
        }
            break;
        case SCN3DDisplayMode_VR360: {
        }
            break;
        case SCN3DDisplayMode_VRGlass: {
        }
            break;
            
        default:
            break;
    }
}

- (void)setCurrentScale:(float)curScale {
    self.curScale = curScale;
    self.shapeNode.scale = SCNVector3Make(curScale, curScale, curScale);
}

- (void)setMinScale:(float)minScale maxScale:(float)maxScale {
    self.minScale = minScale;
    self.maxScale = maxScale;
}

- (void)setCurrentRotateX:(float)rotateX rotateY:(float)rotateY {
    [self changeNodeTransformWithRotateX:GLKMathDegreesToRadians(-rotateX) rotateY:GLKMathDegreesToRadians(-rotateY)];
}

- (void)setVerticalMinRotate:(float)minRotate maxRotate:(float)maxRotate {
    if (minRotate < -90) {
        minRotate = -90;
    }
    if (maxRotate > 90) {
        maxRotate = 90;
    }
    self.minRotateX = GLKMathDegreesToRadians(minRotate);
    self.maxRotateX = GLKMathDegreesToRadians(maxRotate);
}

- (void)setTextureOffsetX:(float)x offsetY:(float)y {
    SCNMatrix4 contentsTransform = self.shapeNode.geometry.firstMaterial.diffuse.contentsTransform;
    contentsTransform = SCNMatrix4Translate(contentsTransform, x, 0, 0);
    contentsTransform = SCNMatrix4Translate(contentsTransform, 0, y, 0);
    self.shapeNode.geometry.firstMaterial.diffuse.contentsTransform = contentsTransform;
}

- (void)setTextureScaleX:(float)x ScaleY:(float)y {
    SCNMatrix4 contentsTransform = self.shapeNode.geometry.firstMaterial.diffuse.contentsTransform;
    contentsTransform = SCNMatrix4Scale(contentsTransform, x, 1.0, 1.0);
    contentsTransform = SCNMatrix4Scale(contentsTransform, 1.0, y, 1.0);
    self.shapeNode.geometry.firstMaterial.diffuse.contentsTransform = contentsTransform;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark SCN3DPlayer Video Image
/////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setFramesPerVideoImage:(UIImage *)image {
    if (image == nil || image.size.width == 0 || image.size.height == 0) {
        self.shapeNode.geometry.firstMaterial.diffuse.contents = self.backgroundColor;
    }
    else {
        self.shapeNode.geometry.firstMaterial.diffuse.contents = image;
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITouchEvent And PinchScale
/////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint currLoc = [touch locationInView:self];
    CGPoint lastLoc = [touch previousLocationInView:self];
    CGPoint moveDiff = CGPointMake(currLoc.x - lastLoc.x, currLoc.y - lastLoc.y);
    
    float rotX = -1 * GLKMathDegreesToRadians(moveDiff.y / 5.0);
    float rotY = -1 * GLKMathDegreesToRadians(moveDiff.x / 5.0);
    
    rotX = self.verticalEnabled   ? rotX : 0;
    rotY = self.horizontalEnabled ? rotY : 0;
    [self changeNodeTransformWithRotateX:rotX / self.curScale rotateY:rotY / self.curScale];
}

- (void)changeNodeTransformWithRotateX:(float)rotX rotateY:(float)rotY {
    switch (self.displayMode) {
        case SCN3DDisplayMode_Plane_Normal: {}
            break;
        case SCN3DDisplayMode_Plane_Slide: {
            SCNMatrix4 contentsTransform = self.shapeNode.geometry.firstMaterial.diffuse.contentsTransform;
            contentsTransform = SCNMatrix4Translate(contentsTransform, rotY, 0, 0);
            contentsTransform = SCNMatrix4Translate(contentsTransform, 0, rotX, 0);
            self.shapeNode.geometry.firstMaterial.diffuse.contentsTransform = contentsTransform;
        }
            break;
        case SCN3DDisplayMode_Tube: {
            self.rotateX += rotX;
            self.rotateY += rotY;
            float minRotate = self.minRotateX / self.curScale;
            float maxRotate = self.maxRotateX / self.curScale;
            
            minRotate = minRotate < (- M_PI / 2) ? (- M_PI / 2) : minRotate;
            maxRotate = maxRotate > (+ M_PI / 2) ? (+ M_PI / 2) : maxRotate;
            self.rotateX = self.rotateX < minRotate ? minRotate : self.rotateX;
            self.rotateX = self.rotateX > maxRotate ? maxRotate : self.rotateX;
            
            SCNMatrix4 modelViewMatrix = SCNMatrix4Identity;
            modelViewMatrix = SCNMatrix4Rotate(modelViewMatrix, -self.rotateY, 0, 1, 0);
            modelViewMatrix = SCNMatrix4Rotate(modelViewMatrix, -self.rotateX, 1, 0, 0);
            modelViewMatrix = SCNMatrix4Scale(modelViewMatrix, self.curScale, self.curScale, self.curScale);
            self.shapeNode.transform = modelViewMatrix;
        }
            break;
        case SCN3DDisplayMode_Sphere: {
            self.rotateX += rotX;
            self.rotateY += rotY;
            float minRotate = self.minRotateX / self.curScale;
            float maxRotate = self.maxRotateX / self.curScale;
            
            minRotate = minRotate < (- M_PI / 2) ? (- M_PI / 2) : minRotate;
            maxRotate = maxRotate > (+ M_PI / 2) ? (+ M_PI / 2) : maxRotate;
            self.rotateX = self.rotateX < minRotate ? minRotate : self.rotateX;
            self.rotateX = self.rotateX > maxRotate ? maxRotate : self.rotateX;
            
            SCNMatrix4 modelViewMatrix = SCNMatrix4Identity;
            modelViewMatrix = SCNMatrix4Rotate(modelViewMatrix, -self.rotateY, 0, 1, 0);
            modelViewMatrix = SCNMatrix4Rotate(modelViewMatrix, -self.rotateX, 1, 0, 0);
            modelViewMatrix = SCNMatrix4Scale(modelViewMatrix, self.curScale, self.curScale, self.curScale);
            self.shapeNode.transform = modelViewMatrix;
        }
            break;
            
        default: {
            self.rotateX += -rotX;
            self.rotateY += -rotY;
            float minRotate = self.minRotateX / self.curScale;
            float maxRotate = self.maxRotateX / self.curScale;
            
            minRotate = minRotate < (- M_PI / 2) ? (- M_PI / 2) : minRotate;
            maxRotate = maxRotate > (+ M_PI / 2) ? (+ M_PI / 2) : maxRotate;
            self.rotateX = self.rotateX < minRotate ? minRotate : self.rotateX;
            self.rotateX = self.rotateX > maxRotate ? maxRotate : self.rotateX;
//            NSLog(@"self.rotateX = %f, %f", self.rotateX, GLKMathRadiansToDegrees(self.rotateX));
            
            SCNMatrix4 modelViewMatrix = SCNMatrix4Identity;
            modelViewMatrix = SCNMatrix4Rotate(modelViewMatrix, -self.rotateY, 0, 1, 0);
            modelViewMatrix = SCNMatrix4Rotate(modelViewMatrix, -self.rotateX, 1, 0, 0);
            modelViewMatrix = SCNMatrix4Scale(modelViewMatrix, self.curScale, self.curScale, self.curScale);
            self.shapeNode.transform = modelViewMatrix;
        }
            break;
    }
}

- (void)handlePinchScale:(UIPinchGestureRecognizer *)paramSender {
    if (!self.pinchEnabled) return;
    if (paramSender.state != UIGestureRecognizerStateEnded && paramSender.state != UIGestureRecognizerStateFailed) {
        if (paramSender.scale != NAN && paramSender.scale != 0.0) {
            
            float scale = (paramSender.scale - 1) * 0.50;
            self.curScale = scale + self.prevScale;
            
            if (self.curScale < self.minScale) {
                self.curScale = self.minScale;
            }
            else if (self.curScale > self.maxScale) {
                self.curScale = self.maxScale;
            }
            
            [self setCurrentScale:self.curScale];
        }
    } else if(paramSender.state == UIGestureRecognizerStateEnded) {
        self.prevScale = self.curScale;
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark G-SENSOR Motion
/////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)startGSENSORMotion {
    float gFPS = 30.0f;
    if (self.displayMode == SCN3DDisplayMode_VRGlass) {
        gFPS = 120.0f;
    }
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.deviceMotionUpdateInterval = 1.0f / gFPS;
    self.motionManager.gyroUpdateInterval = 1.0f / gFPS;
    self.motionManager.showsDeviceMovementDisplay = YES;
    self.rotateX = 0.0f;
    self.rotateY = 0.0f;
    
    NSOperationQueue* motionQueue = [[NSOperationQueue alloc] init];
    [self.motionManager startDeviceMotionUpdatesToQueue:motionQueue withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
        float  damping = 30.0;
        double rotateX = -motion.rotationRate.y / damping;  // X 轴旋转
        double rotateY = -motion.rotationRate.x / damping;  // Y 轴旋转
        
        switch (self.orientation) {
            case UIDeviceOrientationLandscapeRight:
                rotateX = +motion.rotationRate.x / damping;
                rotateY = -motion.rotationRate.y / damping;
                break;
            case UIDeviceOrientationLandscapeLeft:
                rotateX = -motion.rotationRate.x / damping;
                rotateY = +motion.rotationRate.y / damping;
                break;
            case UIDeviceOrientationPortrait:
            default:
                break;
        }
        [self changeNodeTransformWithRotateX:(rotateY / 2) / self.curScale rotateY:rotateX / self.curScale];
    }];
}

- (void)stopGSENSORMotion {
    [self.motionManager stopDeviceMotionUpdates];
    self.motionManager = nil;
}

@end
