//
//  SongListView.h
//  MusicDemo
//
//  Created by olami on 2018/6/29.
//  Copyright © 2018年 VIA Technologies, Inc. & OLAMI Team. All rights reserved.
//


#import <UIKit/UIKit.h>

@protocol SongListViewDelegate
- (void)selectCell:(NSUInteger) index;
@end

/**
 用来显示歌曲列表
 */
@interface SongListView : UIView
@property (nonatomic, copy) NSArray *musicDataArray;
@property (nonatomic, weak) id<SongListViewDelegate> delegate;

@end
