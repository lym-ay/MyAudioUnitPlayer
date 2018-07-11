//
//  MusicViewModel.m
//  MusicDemo
//
//  Created by olami on 2018/6/25.
//  Copyright © 2018年 VIA Technologies, Inc. & OLAMI Team. All rights reserved.
//

#import "MusicViewModel.h"


@implementation MusicViewModel

- (id)init{
    if (self = [super init]) {
        _musicDataArray = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void)processMusic:(completeSearch)block{
    //    NSArray *arry = @[@"zj",@"MP3Sample",@"by"];
    //    for (NSString *name in arry) {
    //        [self getLocalSong:name complete:block];
    //    }
    [self getNetMusic];
    block(YES);
}

- (void)getNetMusic{
    
    NSURL *url5 = [NSURL URLWithString:@"http://baxiang.qiniudn.com/chengdu.mp3"];
    MusicData *data5 = [[MusicData alloc] init];
    data5.songName =@"成都";
    data5.songSinger = @"赵雷";
    data5.songUrl = url5;
    data5.songAlbum = @"新曲-精选全纪录";
    [self.musicDataArray addObject:data5];
   
    
//    NSURL *url2 = [NSURL URLWithString:@"http://fs.w.kugou.com/201807101430/80c384487ee1bacee9bf508aacd3a466/G123/M02/02/05/G4cBAFsL1ziAS-DzADYG0X9H7Es796.mp3"];
//    MusicData *data2 = [[MusicData alloc] init];
//    data2.songName =@"盛夏的果实";
//    data2.songSinger = @"莫文蔚";
//    data2.songUrl = url2;
//    data2.songAlbum = @"新曲-精选全纪录";
//    NSString *picPath2 = [[NSBundle mainBundle] pathForResource:@"mo1" ofType:@"jpg"];
//    UIImage *img2 = [UIImage imageNamed:picPath2];
//    data2.songImage = img2;
//    [self.musicDataArray addObject:data2];
//    
//    NSURL *url1 = [NSURL URLWithString:@"http://fs.w.kugou.com/201807101430/8493a5456c80b4ba465f3a3fc30820f1/G005/M08/0A/08/RQ0DAFS4VmuAfWyVAD9Zeh2Kn8c162.mp3"];
//    MusicData *data1 = [[MusicData alloc] init];
//    data1.songName =@"阴天";
//    data1.songSinger = @"莫文蔚";
//    data1.songUrl = url1;
//    data1.songAlbum = @"you can";
//    NSString *picPath1 = [[NSBundle mainBundle] pathForResource:@"mo2" ofType:@"jpg"];
//    UIImage *img1 = [UIImage imageNamed:picPath1];
//    data1.songImage = img1;
//    [self.musicDataArray addObject:data1];
//    
//    NSURL *url3 = [NSURL URLWithString:@"http://fs.w.kugou.com/201807101430/b1d08377e303c96e50fc5658b409cc5b/G004/M01/16/00/pIYBAFS7foqATjDhADrs0BpdZrQ568.mp3"];
//    MusicData *data3 = [[MusicData alloc] init];
//    data3.songName =@"如果你是李白";
//    data3.songSinger = @"莫文蔚";
//    data3.songUrl = url3;
//    data3.songAlbum = @"[i]";
//    NSString *picPath3 = [[NSBundle mainBundle] pathForResource:@"mo3" ofType:@"jpg"];
//    UIImage *img3 = [UIImage imageNamed:picPath3];
//    data3.songImage = img3;
//    [self.musicDataArray addObject:data3];
//    
//    NSURL *url4 = [[NSBundle mainBundle] URLForResource:@"by" withExtension:@"mp3"];
//    MusicData *data4= [[MusicData alloc] init];
//    data4.songName =@"冰雨";
//    data4.songSinger = @"刘德华";
//    data4.songUrl = url4;
//    data4.songAlbum = @"2012世界巡回演唱会";
//    [self.musicDataArray addObject:data4];
   
    
  
    
    
    
    
    
    
}

 

@end
