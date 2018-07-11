//
//  MusicViewController.m
//  MusicDemo
//
//  Created by olami on 2018/6/22.
//  Copyright © 2018年 VIA Technologies, Inc. & OLAMI Team. All rights reserved.
//

#import "MusicViewController.h"
#import "MusicViewModel.h"
#import "MusicPlayerController.h"
#import "SongListView.h"
#import "AudioPlayerController.h"

@interface MusicViewController ()<MusicPlayerControllerDelegate,SongListViewDelegate>{
    SongCircle buttonIndex;
}
@property (nonatomic, strong) MusicViewModel *viewModel;
@property (weak, nonatomic) IBOutlet UILabel *songName;
@property (weak, nonatomic) IBOutlet UILabel *songSingerAlbum;
@property (weak, nonatomic) IBOutlet UIImageView *songPic;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (weak, nonatomic) IBOutlet UILabel *eclipseTime;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;
@property (weak, nonatomic) IBOutlet UISlider *sliderButton;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;

@property (weak, nonatomic) IBOutlet UIButton *circleButton;
//@property (strong, nonatomic) MusicPlayerController *musicPlayer;
@property (strong, nonatomic) SongListView *songListView;
@property (strong, nonatomic) NSArray *circleButtonArray;
@property (strong, nonatomic) AudioPlayerController *musicPlayer;
 
@end

@implementation MusicViewController




- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.sliderButton setThumbImage:[UIImage imageNamed:@"nail"] forState:UIControlStateNormal];
    
    UIImage *img0 = [UIImage imageNamed:@"single"];
    UIImage *img1 = [UIImage imageNamed:@"circle"];
    UIImage *img2 = [UIImage imageNamed:@"random"];
    _circleButtonArray = @[img0,img1,img2];
    [_circleButton setImage:img0 forState:UIControlStateNormal];
    buttonIndex = Single;
   
    
    _viewModel = [[MusicViewModel alloc] init];
    
    self.musicPlayer = [[AudioPlayerController alloc] init];
    self.musicPlayer.delegate = self;
    
    _songListView = [[SongListView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    _songListView.delegate = self;
    [self.view addSubview:_songListView];
    
    
    
    __weak MusicViewController *weakSelf = self;
    [_viewModel processMusic:^(BOOL result) {
        if (result) {
            weakSelf.musicPlayer.musicDataArray = weakSelf.viewModel.musicDataArray;
            weakSelf.songListView.musicDataArray = weakSelf.viewModel.musicDataArray;
        if (weakSelf.musicPlayer.songStatus == StopStatus) {
                [weakSelf.musicPlayer playIndex:0];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                 [weakSelf updateUI];
            });
           
           
            
        }
    }];
    
    [self.sliderButton addTarget:self action:@selector(touchUp)
          forControlEvents:UIControlEventValueChanged|UIControlEventTouchUpInside];//当滑块上的按钮的位置发生改变，或者被按下时，我们需要让歌曲先暂停。
    [self.sliderButton addTarget:self action:@selector(touchDown)
          forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];//当滑块被松开，按到外面了，或者取消时，我们需要让歌曲的播放从当前的时间开始播放。
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}




- (void)updateUI{
    NSUInteger index = self.musicPlayer.index;
    
    MusicData *data = _viewModel.musicDataArray[index];
    _songName.text = data.songName;
    
    NSString *title = [NSString stringWithFormat:@"%@ - %@",data.songSinger,data.songAlbum];
    _songSingerAlbum.text = title;
    
    if (data.songImage) {
        [_songPic setImage:data.songImage];
    }else{
        [_songPic setImage:[UIImage imageNamed:@"songpic"]];
    }
    
    [_playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    
}





- (IBAction)circleButton:(id)sender {
    switch (buttonIndex) {
        case Single:
            buttonIndex++;
            break;
        case Circle:
            buttonIndex++;
            break;
        case Random:
            buttonIndex = Single;
            break;
            
        default:
            break;
    }
    
    UIImage *img = _circleButtonArray[buttonIndex];
    [_circleButton setImage:img forState:UIControlStateNormal];
}

- (IBAction)prevSong:(id)sender {
    [_progressBar setProgress:0];
    [self.musicPlayer prevSong];
    [self updateUI];
    
    
    
}

- (IBAction)playSong:(id)sender {
    if (self.musicPlayer.songStatus == PlayStatus) {
        [_playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    }else if (self.musicPlayer.songStatus == PauseStatus){
         [_playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    }
    
    [self.musicPlayer pause];
}


- (IBAction)nextSong:(id)sender {
    [_progressBar setProgress:0];
    [self.musicPlayer nextSong];
    [self updateUI];
}



- (void)touchUp{
    NSTimeInterval curTime = _sliderButton.value;
    NSInteger min = curTime/60;
    NSInteger sec = (NSInteger)curTime%60;
    _eclipseTime.text = [NSString stringWithFormat:@"%02ld:%02ld",min,sec];
    
    [self.musicPlayer seekStart];
}

- (void)touchDown{
    if (self.musicPlayer.songStatus == PlayStatus) {
        [self.musicPlayer seekToTime:_sliderButton.value];
        [self.musicPlayer seekEnd];
        
    }
}

- (void)setCurrentTime:(NSTimeInterval)time duration:(NSTimeInterval)duration{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimeInterval totalTime = duration;
        NSInteger min = totalTime/60;
        NSInteger sec = (NSInteger)totalTime%60;
        self.totalTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld",min,sec];
        
        self.sliderButton.maximumValue= duration;
        self.sliderButton.minimumValue = 0;
        self.sliderButton.value = time;
        //NSLog(@"time is %f",self.sliderButton.value);
        
        
        NSTimeInterval curTime = time;
        NSInteger min1 = curTime/60;
        NSInteger sec1 = (NSInteger)curTime%60;
        self.eclipseTime.text =  [NSString stringWithFormat:@"%02ld:%02ld",min1,sec1];
        
    });
   
    
}

- (void)playbackComplete{
    switch (buttonIndex) {
        case Single:
            [_progressBar setProgress:0];
            [self.musicPlayer playIndex:self.musicPlayer.index];
            break;
        case Circle:
            [self.musicPlayer nextSong];
            break;
        case Random:{
            [_progressBar setProgress:0];
            int index = arc4random()%(_viewModel.musicDataArray.count);
            [self.musicPlayer playIndex:index];
        }
           
            break;
            
        default:
            break;
    }
   
    dispatch_async(dispatch_get_main_queue(), ^{
         [self updateUI];
    });
}

- (void)updatePrograssBar:(NSTimeInterval)time{
     dispatch_async(dispatch_get_main_queue(), ^{
         [self.progressBar setProgress:time animated:YES];
     });
}

- (void)playError{
    [self.musicPlayer nextSong];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateUI];
    });
}
 
- (IBAction)songListView:(id)sender {
    [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [self.songListView setFrame:self.view.frame];
    } completion:nil];
    
    
}

- (void)selectCell:(NSUInteger)index{
    [_progressBar setProgress:0];
    [self.musicPlayer playIndex:index];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateUI];
    });
}


@end
