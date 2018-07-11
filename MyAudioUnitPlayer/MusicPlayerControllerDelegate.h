//
//  MusicPlayerControllerDelegate.h
//  MusicDemo
//
//  Created by olami on 2018/7/6.
//  Copyright © 2018年 VIA Technologies, Inc. & OLAMI Team. All rights reserved.
//

#ifndef MusicPlayerControllerDelegate_h
#define MusicPlayerControllerDelegate_h
@protocol MusicPlayerControllerDelegate
- (void)setCurrentTime:(NSTimeInterval)time duration:(NSTimeInterval)duration;
- (void)playbackComplete;
- (void)updatePrograssBar:(NSTimeInterval)time;
- (void)playError;//播放出错。
@end;

#endif /* MusicPlayerControllerDelegate_h */
