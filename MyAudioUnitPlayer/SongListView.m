//
//  SongListView.m
//  MusicDemo
//
//  Created by olami on 2018/6/29.
//  Copyright © 2018年 VIA Technologies, Inc. & OLAMI Team. All rights reserved.
//

#import "SongListView.h"
#import "MusicData.h"

@interface SongListView()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView  *backView;
@end

@implementation SongListView

- (id)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    
    return  self;
}


- (void)setupUI{
    self.backgroundColor = [UIColor clearColor];
    
    _backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
     self.backView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    [self addSubview:self.backView];
   
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapView)];
    [self.backView addGestureRecognizer:tap];
    
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, self.frame.size.height/3, self.frame.size.width, 60)];
    label.text = @"歌曲列表";
    label.backgroundColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    [self addSubview:label];
    
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.frame.size.height/3+60, self.frame.size.width, self.frame.size.height)];
    [self addSubview:_tableView];
    _tableView.delegate  = self;
    _tableView.dataSource = self;
    
    
    
}

- (void)setMusicDataArray:(NSArray *)musicDataArray{
    _musicDataArray = [musicDataArray copy];
}

- (void)tapView{
    [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseOut    animations:^{
        [self setFrame:CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT)];
    } completion:nil];
}

#pragma mark --UITableDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _musicDataArray.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"songcell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"songcell"];
        MusicData *data = self.musicDataArray[indexPath.row];
        NSString *title = [NSString stringWithFormat:@"%@ - %@",data.songName,data.songSinger];
        cell.textLabel.text = title;
        
    }
    //cell选中效果
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
 
    
    return 50;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate selectCell:indexPath.row];
}



@end
