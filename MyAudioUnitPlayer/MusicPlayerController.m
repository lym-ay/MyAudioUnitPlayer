//
//  MusicNetPlayerController.m
//  MusicDemo
//
//  Created by olami on 2018/6/26.
//  Copyright © 2018年 VIA Technologies, Inc. & OLAMI Team. All rights reserved.
//

#import "MusicPlayerController.h"
#import <AVFoundation/AVFoundation.h>
#import "MusicData.h"


static const NSString *PlayerItemStatusContext;
@interface MusicPlayerController()
@property (nonatomic, strong) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) id timeObserver;
@property (strong, nonatomic) id itemEndObserver;

@end


@implementation MusicPlayerController


- (id)init{
    if (self = [super init]) {
        _songStatus = StopStatus;
    }
    
    return self;
}

- (void)setMusicDataArray:(NSArray *)musicDataArray{
    _musicDataArray = [musicDataArray copy];
}


- (void)playIndex:(NSUInteger)index{
    [self removeAllObservers];
    MusicData *data = self.musicDataArray[index];
    _index = index;
    NSArray *keys = @[
                      @"tracks",
                      @"duration",
                      @"commonMetadata",
                      @"availableMediaCharacteristicsWithMediaSelectionOptions"
                      ];
    AVAsset *asset = [AVURLAsset URLAssetWithURL:data.songUrl options:nil];
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset automaticallyLoadedAssetKeys:keys];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.player.volume = 0.3;
    //添加键盘
    [self.playerItem addObserver:self forKeyPath:@"status" options:0 context:&PlayerItemStatusContext];
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    _songStatus = PlayStatus;
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    
    if ([keyPath isEqualToString:@"status"]) {
        
     
        
            if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
                
                // Set up time observers.                                   // 2
                [self addPlayerItemTimeObserver];
                [self addItemEndObserverForPlayerItem];
                
                CMTime duration = self.playerItem.duration;
                
                // Synchronize the time display                             // 3
                [self.delegate setCurrentTime:CMTimeGetSeconds(kCMTimeZero)
                                     duration:CMTimeGetSeconds(duration)];
                
                
                [self.player play];                                         // 5
                
                
                
            } else if ([self.playerItem status] == AVPlayerStatusFailed || [self.playerItem status] == AVPlayerStatusUnknown) {
                [_player pause];
                [self.delegate playError];
            }
        }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {  //监听播放器的下载进度
            //[self.playerItem removeObserver:self forKeyPath:@"status"];
            NSArray *loadedTimeRanges = [self.playerItem loadedTimeRanges];
            CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
            float startSeconds = CMTimeGetSeconds(timeRange.start);
            float durationSeconds = CMTimeGetSeconds(timeRange.duration);
            NSTimeInterval timeInterval = startSeconds + durationSeconds;// 计算缓冲总进度
            CMTime duration = self.playerItem.duration;
            NSTimeInterval totalDuration = CMTimeGetSeconds(duration);
            NSTimeInterval progressTime = timeInterval / totalDuration;
            NSLog(@"下载进度：%.2f", timeInterval);
            [self.delegate updatePrograssBar:progressTime];
            
        } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) { //监听播放器在缓冲数据的状态
            
            NSLog(@"缓冲不足暂停了");
            
            
        } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            
            NSLog(@"缓冲达到可播放程度了");
            
            //由于 AVPlayer 缓存不足就会自动暂停，所以缓存充足了需要手动播放，才能继续播放
            [_player play];
            
        }

}

- (void)removeAllObservers{
    
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [self.player removeTimeObserver:self.timeObserver];
    self.timeObserver = nil;
    
    
    
}

/**
 实时监控播放的进度
 */
- (void)addPlayerItemTimeObserver{
    CMTime interval = CMTimeMakeWithSeconds(1,  NSEC_PER_SEC);
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    __weak MusicPlayerController *weakSelf = self;
    void (^callback)(CMTime time) = ^(CMTime time){
        NSTimeInterval currentTime = CMTimeGetSeconds(time);
        NSTimeInterval duration = CMTimeGetSeconds(weakSelf.playerItem.duration);
        [weakSelf.delegate setCurrentTime:currentTime duration:duration];
    };
    
   self.timeObserver =  [self.player addPeriodicTimeObserverForInterval:interval queue:queue usingBlock:callback];
}


/**
 当播放完毕的时候回调
 */
- (void)addItemEndObserverForPlayerItem{
    NSString *name = AVPlayerItemDidPlayToEndTimeNotification;
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    __weak MusicPlayerController *weakSelf = self;
    self.itemEndObserver = [[NSNotificationCenter defaultCenter] addObserverForName:name object:self.playerItem queue:queue usingBlock:^(NSNotification * _Nonnull note) {
        [weakSelf.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
            [weakSelf.delegate playbackComplete];
        }];
    }];
}


- (void)pause{
    if (self.player.timeControlStatus == AVPlayerTimeControlStatusPlaying) {
        [self.player pause];
        _songStatus = PauseStatus;
    }else{
        [self.player play];
        _songStatus = PlayStatus;
    }
}

- (void)stop{
    
}

- (void)prevSong{
    if (_index == 0) {
        //如果是第一首，就播放最后一首
        _index = _musicDataArray.count -1;
    }else{
        _index--;
    }
 
    [self playIndex:_index];
}

- (void)nextSong{
    if (_index == _musicDataArray.count -1) {
        //如果是最后一首，播放第一首
        _index = 0;
    }else{
        _index++;
    }
    [self playIndex:_index];
}

- (void)seekToTime:(NSTimeInterval)time{
    [self.playerItem cancelPendingSeeks];
    [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)seekStart{
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}

- (void)seekEnd{
    [self addPlayerItemTimeObserver];
}

- (void)dealloc{
    [self removeAllObservers];
}


@end
