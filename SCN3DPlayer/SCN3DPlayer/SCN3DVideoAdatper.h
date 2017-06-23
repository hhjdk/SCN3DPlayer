//
//  SCN3DVideoAdatper.h
//  SCN3DPlayer
//
//  Created by 俞涛涛 on 16/11/11.
//  Copyright © 2016年 俞涛涛. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


/////////////////////////////////////////////////////////////////////////////////////////////////////////

@class SCN3DVideoAdatper;

@protocol SCN3DVideoAdatperDelegate <NSObject>

@optional

/**
 准备播放视频
 实现SCN3DVideoAdatperDelegate协议最先调用该方法

 @param videoAdatper SCN3DVideoAdatper对象

 */
- (void)videoPlayerIsReadyToPlayVideo:(SCN3DVideoAdatper *)videoAdatper;

/**
 播放视频结束
 实现SCN3DVideoAdatperDelegate协议 在视频播放结束以后调用该方法

 @param videoAdatper SCN3DVideoAdatper
 */
- (void)videoPlayerDidReachEnd:(SCN3DVideoAdatper *)videoAdatper;

/**
 播放时间监听
 实现SCN3DVideoAdatperDelegate协议 在视频播放时会返回当前播放的时间

 @param videoAdatper SCN3DVideoAdatper 对象
 @param cmTime  CMTime
 */
- (void)videoPlayer:(SCN3DVideoAdatper *)videoAdatper timeDidChange:(CMTime)cmTime;

/**
 播放已加载的缓存时间监听
 实现SCN3DVideoAdatperDelegate协议 在视频播放的时候会返回当前已加载的视频缓存百分比
 @param videoAdatper SCN3DVideoAdatper 对象
 @param duration float
 */
- (void)videoPlayer:(SCN3DVideoAdatper *)videoAdatper loadedTimeRangeDidChange:(float)duration;

/**
 播放错误监听
 实现SCN3DVideoAdatperDelegate协议 在播放视频失败的时候会调用该方法

 @param videoAdatper SCN3DVideoAdatper 对象
 @param error  NSError 对象
 */
- (void)videoPlayer:(SCN3DVideoAdatper *)videoAdatper didFailWithError:(NSError *)error;

/**
 获取视频的每一帧
 实现SCN3DVideoAdatperDelegate协议 在视频播放的时候，该方法可以得到视频得每一帧图片

 @param videoAdatper SCN3DVideoAdatper 对象
 @param videoImage UIImage 对象
 */
- (void)videoPlayer:(SCN3DVideoAdatper *)videoAdatper displaylinkCallbackImage:(UIImage *)videoImage;

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface SCN3DVideoAdatper : NSObject

@property (nonatomic, weak) id<SCN3DVideoAdatperDelegate> delegate;
@property (nonatomic, strong, readonly) AVPlayer     *player;
@property (nonatomic, strong, readonly) AVPlayerItem *playerItem;
@property (nonatomic, strong, readonly) AVPlayerItemVideoOutput *output;
@property (nonatomic, assign, getter=isPlaying, readonly) BOOL playing;
@property (nonatomic, assign, getter=isLooping) BOOL looping;
@property (nonatomic, assign, getter=isMuted) BOOL muted;

// Setting

- (void)setURL:(NSURL *)URL;
- (void)setPlayerItem:(AVPlayerItem *)playerItem;
- (void)setAsset:(AVAsset *)asset;


// 开始播放
- (void)play;
//暂停播放
- (void)pause;
//重置播放器
- (void)reset;

/**
 跳转到相应的时间段
 在相应的时间段里面播放

 @param time 传入一个float 得参数，
 @param completion completion description
 */
- (void)seekToTime:(float)time completion:(void (^)())completion;

//设置音量大小
- (void)setVolume:(float)volume;
//增加音量
- (void)fadeInVolume;
//降低音量
- (void)fadeOutVolume;

// 添加 Displaylink
- (void)addDisplaylink;
// 移除  Displaylink
- (void)removeDisplaylink;

@end
