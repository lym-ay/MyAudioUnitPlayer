//
//  AudioPlayerController.h
//  MusicDemo
//
//  Created by olami on 2018/7/10.
//  Copyright © 2018年 VIA Technologies, Inc. & OLAMI Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MusicPlayerControllerDelegate.h"

@interface AudioPlayerController : NSObject
@property (nonatomic, copy) NSArray *musicDataArray;
@property (nonatomic, assign) SongStatus songStatus;
@property (nonatomic, assign) NSUInteger index;//当前播放歌曲的索引值
 @property (nonatomic, weak) id<MusicPlayerControllerDelegate> delegate;
- (void)playIndex:(NSUInteger) index;
- (void)pause;
- (void)stop;
- (void)prevSong;
- (void)nextSong;
- (void)seekToTime:(NSTimeInterval)time;
- (void)seekStart;
- (void)seekEnd;
@end
