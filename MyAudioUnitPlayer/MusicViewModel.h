//
//  MusicViewModel.h
//  MusicDemo
//
//  Created by olami on 2018/6/25.
//  Copyright © 2018年 VIA Technologies, Inc. & OLAMI Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MusicData.h"
/**
 用来获得并解析音乐数据的类，这是个父类，根据音乐的来源不同：本地音乐和网络音乐
 来分别子类化。在父类中，主要保存解析后的音乐数据
 */

typedef void (^completeSearch)(BOOL result);

@interface MusicViewModel : NSObject
@property (nonatomic, copy) NSMutableArray *musicDataArray;

/**
 处理音乐的函数

 @param block 由于处理时间可能过长，返回一个 block，告诉主界面是否成功
 */
- (void)processMusic:(completeSearch) block;


@end
