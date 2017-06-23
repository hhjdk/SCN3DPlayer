//
//  SCN3DVideoAdatper.m
//  SCN3DPlayer
//
//  Created by 俞涛涛 on 16/11/11.
//  Copyright © 2016年 俞涛涛. All rights reserved.
//

#import "SCN3DVideoAdatper.h"
#import <UIKit/UIKit.h>

static const float DefaultVolumeFadeDuration = 1.0f;
static const float TimeObserverInterval      = 0.01f;

static NSString * const kVideoPlayerErrorDomain   = @"kVideoPlayerErrorDomain";
static void *VideoPlayer_PlayerItemStatusContext  = &VideoPlayer_PlayerItemStatusContext;
static void *VideoPlayer_PlayerRateChangedContext = &VideoPlayer_PlayerRateChangedContext;
static void *VideoPlayer_PlayerItemLoadedTimeRangesContext = &VideoPlayer_PlayerItemLoadedTimeRangesContext;

/////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface SCN3DVideoAdatper ()

@property (nonatomic, strong, readwrite) AVPlayer *player;
@property (nonatomic, strong, readwrite) AVPlayerItem *playerItem;
@property (nonatomic, strong, readwrite) AVPlayerItemVideoOutput *output;

@property (nonatomic, assign, getter=isPlaying, readwrite) BOOL playing;
@property (nonatomic, assign, getter=isSeeking) BOOL seeking;
@property (nonatomic, assign) BOOL isAtEndTime;
@property (nonatomic, strong) id timeObserverToken;
@property (nonatomic, strong) CADisplayLink *displayLink;  // 同步显示器的刷新频率

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation SCN3DVideoAdatper

- (void)dealloc {
    [self resetPlayerItemIfNecessary];
    [self removePlayerObservers];
    [self removeTimeObserver];
    [self cancelFadeVolume];
    NSLog(@"===============player dealloc===========");
}

- (id)init {
    if (self = [super init]) {
        [self setupPlayer];
        [self addPlayerObservers];
        [self setupAudioSession];
        NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
        self.output = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
    }
    return self;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Setup
/////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setupPlayer {
    self.player  = [[AVPlayer alloc] init];
    self.muted   = NO;
    self.looping = NO;
    [self setVolume:1.0f];
    [self addTimeObserver];
}

- (void)setupAudioSession {
    NSError *categoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&categoryError];
    if (!success) {
        NSLog(@"Error setting audio session category: %@", categoryError);
    }
    
    NSError *activeError = nil;
    success = [[AVAudioSession sharedInstance] setActive:YES error:&activeError];
    if (!success) {
        NSLog(@"Error setting audio session active: %@", activeError);
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public API
/////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setURL:(NSURL *)URL {
    if (URL == nil) {
        return;
    }
    [self resetPlayerItemIfNecessary];
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:URL];
    if (!playerItem) {
        [self reportUnableToCreatePlayerItem];
        return;
    }
    [self preparePlayerItem:playerItem];
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    if (playerItem == nil) {
        return;
    }
    [self resetPlayerItemIfNecessary];
    [self preparePlayerItem:playerItem];
}

- (void)setAsset:(AVAsset *)asset {
    if (asset == nil) {
        return;
    }
    [self resetPlayerItemIfNecessary];
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:asset automaticallyLoadedAssetKeys:@[NSStringFromSelector(@selector(tracks))]];
    if (!playerItem) {
        [self reportUnableToCreatePlayerItem];
        return;
    }
    [self preparePlayerItem:playerItem];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Accessor Overrides
/////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setMuted:(BOOL)muted {
    if (self.player) {
        self.player.muted = muted;
    }
}

- (BOOL)isMuted {
    return self.player.isMuted;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Playback
/////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)play {
    if (self.player.currentItem == nil) {
        return;
    }
    self.playing = YES;
    
    if ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay) {
        if ([self isAtEndTime]) {
            [self restart];
        }
        else {
            [self.player play];
        }
    }
}

- (void)pause {
    self.playing = NO;
    [self.player pause];
}

- (void)reset {
    [self pause];
    [self resetPlayerItemIfNecessary];
}

- (void)seekToTime:(float)time completion:(void (^)())completion {
    if (_seeking) {
        return;
    }
    
    if (self.player) {
        CMTime cmTime = CMTimeMakeWithSeconds(time, self.player.currentTime.timescale);
        if (CMTIME_IS_INVALID(cmTime) || self.player.currentItem.status != AVPlayerStatusReadyToPlay) {
            return;
        }
        
        _seeking = YES;
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.player seekToTime:cmTime completionHandler:^(BOOL finished) {
                weakSelf.isAtEndTime = NO;
                weakSelf.seeking = NO;
                if (completion) {
                    dispatch_async( dispatch_get_main_queue(), ^{
                        completion();
                    });
                }
            }];
        });
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Volume
/////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setVolume:(float)volume {
    [self cancelFadeVolume];
    self.player.volume = volume;
}

- (void)cancelFadeVolume {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeInVolume) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOutVolume) object:nil];
}

- (void)fadeInVolume {
    if (self.player == nil) {
        return;
    }
    [self cancelFadeVolume];
    
    if (self.player.volume >= 1.0f - 0.01f) {
        self.player.volume = 1.0f;
    }
    else {
        self.player.volume += 1.0f/10.0f;
        [self performSelector:@selector(fadeInVolume) withObject:nil afterDelay:DefaultVolumeFadeDuration/10.0f];
    }
}

- (void)fadeOutVolume {
    if (self.player == nil) {
        return;
    }
    [self cancelFadeVolume];
    
    if (self.player.volume <= 0.01f) {
        self.player.volume = 0.0f;
    }
    else {
        self.player.volume -= 1.0f/10.0f;
        [self performSelector:@selector(fadeOutVolume) withObject:nil afterDelay:DefaultVolumeFadeDuration/10.0f];
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Displaylink
/////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)addDisplaylink {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)removeDisplaylink {
    if (self.displayLink) {
        [self.displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        self.displayLink = nil;
    }
}

- (void)displayLinkCallback:(CADisplayLink *)sender {
    @autoreleasepool {
        CMTime outputItemTime = [self.output itemTimeForHostTime:CACurrentMediaTime()];
        if([self.output hasNewPixelBufferForItemTime:outputItemTime]) {
            CVPixelBufferRef bufferRef = [self.output copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
        
            if (bufferRef != nil) {
                UIImage *videoImage = [self pixelBufferToImage:bufferRef];
                if ([self.delegate respondsToSelector:@selector(videoPlayer:displaylinkCallbackImage:)]) {
                    [self.delegate videoPlayer:self displaylinkCallbackImage:videoImage];
                }
                CFRelease(bufferRef);
            }
        }
    }

}

- (UIImage *)pixelBufferToImage:(CVPixelBufferRef)bufferRef {
    CIImage   *ciImage     = [CIImage imageWithCVPixelBuffer:bufferRef];
    CIContext *tempContext = [CIContext contextWithOptions:nil];
    CGFloat    videoWidth  = CVPixelBufferGetWidth(bufferRef);
    CGFloat    videoHeight = CVPixelBufferGetHeight(bufferRef);
    CGImageRef videoImage  = [tempContext createCGImage:ciImage fromRect:CGRectMake(0, 0, videoWidth, videoHeight)];
    
    UIImage *image = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);
    return image;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private API
/////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)reportUnableToCreatePlayerItem {
    if ([self.delegate respondsToSelector:@selector(videoPlayer:didFailWithError:)]) {
        NSError *error = [NSError errorWithDomain:kVideoPlayerErrorDomain
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey : @"Unable to create AVPlayerItem."}];
        
        [self.delegate videoPlayer:self didFailWithError:error];
    }
}

- (void)resetPlayerItemIfNecessary {
    if (self.playerItem) {
        [self removePlayerItemObservers:self.playerItem];
        [self.player replaceCurrentItemWithPlayerItem:nil];
        [self.playerItem removeOutput:self.output];
        self.playerItem = nil;
    }
    _playing = NO;
    _isAtEndTime = NO;
}

- (void)preparePlayerItem:(AVPlayerItem *)playerItem {
    NSParameterAssert(playerItem);
    _playerItem = playerItem;
    [self addPlayerItemObservers:playerItem];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
}

- (void)restart {
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        weakSelf.isAtEndTime = NO;
        if (weakSelf.isPlaying) {
            [weakSelf play];
        }
    }];
}

- (BOOL)isAtEndTime { // TODO: this is a fucked up override, seems like something could be wrong [AH]
    if (self.player && self.player.currentItem) {
        if (_isAtEndTime) {
            return _isAtEndTime;
        }
        
        float currentTime = 0.0f;
        if (CMTIME_IS_INVALID(self.player.currentTime) == NO) {
            currentTime = CMTimeGetSeconds(self.player.currentTime);
        }
        
        float videoDuration = 0.0f;
        if (CMTIME_IS_INVALID(self.player.currentItem.duration) == NO) {
            videoDuration = CMTimeGetSeconds(self.player.currentItem.duration);
        }
        
        if (currentTime > 0.0f && videoDuration > 0.0f) {
            if (fabs(currentTime - videoDuration) <= 0.01f) {
                return YES;
            }
        }
    }
    return NO;
}

- (float)calcLoadedDuration {
    float loadedDuration = 0.0f;
    if (self.player && self.player.currentItem) {
        NSArray *loadedTimeRanges = self.player.currentItem.loadedTimeRanges;
        
        if (loadedTimeRanges && [loadedTimeRanges count]) {
            CMTimeRange timeRange = [[loadedTimeRanges firstObject] CMTimeRangeValue];
            float startSeconds = CMTimeGetSeconds(timeRange.start);
            float durationSeconds = CMTimeGetSeconds(timeRange.duration);
            loadedDuration = startSeconds + durationSeconds;
        }
    }
    return loadedDuration;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Player Observers
/////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)addPlayerObservers {
    [self.player addObserver:self
                  forKeyPath:NSStringFromSelector(@selector(rate))
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:VideoPlayer_PlayerRateChangedContext];
}

- (void)removePlayerObservers {
    @try {
        [self.player removeObserver:self
                         forKeyPath:NSStringFromSelector(@selector(rate))
                            context:VideoPlayer_PlayerRateChangedContext];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception removing observer: %@", exception);
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PlayerItem Observers
/////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)addPlayerItemObservers:(AVPlayerItem *)playerItem {
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(status))
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                    context:VideoPlayer_PlayerItemStatusContext];
    
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(loadedTimeRanges))
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:VideoPlayer_PlayerItemLoadedTimeRangesContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidPlayToEndTime:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
}

- (void)removePlayerItemObservers:(AVPlayerItem *)playerItem {
    [playerItem cancelPendingSeeks];
    @try {
        [playerItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(status))
                           context:VideoPlayer_PlayerItemStatusContext];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception removing observer: %@", exception);
    }
    
    @try {
        [playerItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(loadedTimeRanges))
                           context:VideoPlayer_PlayerItemLoadedTimeRangesContext];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception removing observer: %@", exception);
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Time Observer
/////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)addTimeObserver {
    if (self.timeObserverToken || self.player == nil) {
        return;
    }
    
    __weak typeof (self) weakSelf = self;
    self.timeObserverToken = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(TimeObserverInterval, NSEC_PER_SEC)
                                                                       queue:dispatch_get_main_queue()
                                                                  usingBlock:^(CMTime time)
    {
        __strong typeof (self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if ([strongSelf.delegate respondsToSelector:@selector(videoPlayer:timeDidChange:)]) {
            [strongSelf.delegate videoPlayer:strongSelf timeDidChange:time];
        }
    }];
}

- (void)removeTimeObserver {
    if (self.timeObserverToken == nil) {
        return;
    }
    if (self.player) {
        [self.player removeTimeObserver:self.timeObserverToken];
    }
    self.timeObserverToken = nil;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Observer Response
/////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == VideoPlayer_PlayerRateChangedContext) {
//        if (self.playerItem != nil) {
//            NSLog(@"TODO: Show loading indicator");
//        }
    }
    else if (context == VideoPlayer_PlayerItemStatusContext) {
        AVPlayerStatus newStatus = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        AVPlayerStatus oldStatus = [[change objectForKey:NSKeyValueChangeOldKey] integerValue];
        
        if (newStatus != oldStatus) {
            switch (newStatus) {
                case AVPlayerItemStatusUnknown: {
                    NSLog(@"Video player Status Unknown");
                }
                    break;
                case AVPlayerItemStatusReadyToPlay: {
                    if ([self.delegate respondsToSelector:@selector(videoPlayerIsReadyToPlayVideo:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.playerItem addOutput:self.output];
                            [self.delegate videoPlayerIsReadyToPlayVideo:self];
                        });
                    }
                }
                    break;
                case AVPlayerItemStatusFailed: {
                    NSLog(@"Video player Status Failed: player item error = %@", self.player.currentItem.error);
                    NSLog(@"Video player Status Failed: player error = %@", self.player.error);
                    
                    NSError *error = self.player.error;
                    if (!error) {
                        error = self.player.currentItem.error;
                    }
                    else {
                        error = [NSError errorWithDomain:kVideoPlayerErrorDomain
                                                    code:0
                                                userInfo:@{NSLocalizedDescriptionKey : @"unknown player error, status == AVPlayerItemStatusFailed"}];
                    }
                    [self reset];
                    
                    if ([self.delegate respondsToSelector:@selector(videoPlayer:didFailWithError:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate videoPlayer:self didFailWithError:error];
                        });
                    }
                }
                    break;
                default:
                    break;
            }
        }
    }
    else if (context == VideoPlayer_PlayerItemLoadedTimeRangesContext) {
        float loadedDuration = [self calcLoadedDuration];
        if ([self.delegate respondsToSelector:@selector(videoPlayer:loadedTimeRangeDidChange:)]) {
            [self.delegate videoPlayer:self loadedTimeRangeDidChange:loadedDuration];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)playerItemDidPlayToEndTime:(NSNotification *)notification {
    if (notification.object != self.player.currentItem) {
        return;
    }
    
    if (self.isLooping) {
        [self restart];
    }
    else {
        _isAtEndTime = YES;
        self.playing = NO;
    }
    
    if ([self.delegate respondsToSelector:@selector(videoPlayerDidReachEnd:)]) {
        [self.delegate videoPlayerDidReachEnd:self];
    }
}

@end
