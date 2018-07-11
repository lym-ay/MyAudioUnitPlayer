//
//  MusicData.h
//  MusicDemo
//
//  Created by olami on 2018/6/25.
//  Copyright © 2018年 VIA Technologies, Inc. & OLAMI Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



/**
 保存音乐数据
 */
@interface MusicData : NSObject
@property(nonatomic, copy)      NSString *songSinger;
@property(nonatomic, copy)      NSString *songName;
@property(nonatomic, strong)    UIImage *songImage;
@property(nonatomic, strong)    NSURL *songUrl;
@property(nonatomic, copy)      NSString *songAlbum;
@end
