//
//  ViewController.m
//  ExampleApp
//
//  Created by mahesh on 19/03/15.
//  Copyright (c) 2015 Thong Nguyen. All rights reserved.
//

#import "ViewController.h"
#import "AudioPlayerView.h"
#import "STKAudioPlayer.h"
#import "STKAudioPlayer.h"
#import "AudioPlayerView.h"
#import "STKAutoRecoveringHTTPDataSource.h"
#import "SampleQueueId.h"
#import <AVFoundation/AVFoundation.h>
#import "EZAudioPlot.h"

@interface ViewController ()<AudioPlayerViewDelegate>
{
    STKAudioPlayer* audioPlayer;
}

@property (weak, nonatomic) IBOutlet AudioPlayerView *audioPlayerView;
@property (strong, nonatomic)IBOutlet EZAudioPlot *audioPlot;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    NSError* error;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    
//    Float32 bufferLength = 0.1;
//    AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(bufferLength), &bufferLength);

//    [[AVAudioSession sharedInstance]  setPreferredIOBufferDuration:bufferLength error:&error];
    
    if (error) {
        NSLog(@"Error: %@",error.localizedDescription);
    }
    
    audioPlayer = [[STKAudioPlayer alloc] initWithOptions:(STKAudioPlayerOptions)
    {
        .flushQueueOnSeek = YES,
        .enableVolumeMixer = YES,
//        .equalizerBandFrequencies = {0,10,20,30,40,50, 100, 200,300, 400,500,600,700, 800,900,1000,1100,1500, 1600, 2600, 16000}
    }];

    audioPlayer.meteringEnabled = YES;
    audioPlayer.volume = 1;
    
    AudioPlayerView* audioPlayerView = [[AudioPlayerView alloc] initWithFrame:self.view.bounds andAudioPlayer:audioPlayer];
    
    audioPlayerView.delegate = self;

    audioPlayerView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:audioPlayerView];
    
    
    //AudioPlot
    
    self.audioPlot = [[EZAudioPlot alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height-220, self.view.frame.size.width, 200)];
    self.audioPlot.backgroundColor = [UIColor whiteColor];
    self.audioPlot.color = [UIColor orangeColor];
    self.audioPlot.plotType = EZPlotTypeRolling;
    self.audioPlot.shouldFill = YES;
    self.audioPlot.shouldMirror = YES;

    
    [self.view addSubview:_audioPlot];

    audioPlayerView.audioPlot = self.audioPlot;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) audioPlayerViewPlayFromHTTPSelected:(AudioPlayerView*)audioPlayerView
{
    //    NSURL* url = [NSURL URLWithString:@"http://www.abstractpath.com/files/audiosamples/sample.mp3"];
    
#warning - ADD ANY WORKING STREAM URL
    
    NSURL* url = [NSURL URLWithString:@"http://localhost:8888/SongsToDownload/AmakeAmarMotoThakteDao.mp3"];
    
    
    STKDataSource* dataSource = [STKAudioPlayer dataSourceFromURL:url];
    
    [audioPlayer setDataSource:dataSource withQueueItemId:[[SampleQueueId alloc] initWithUrl:url andCount:0]];
}

-(void) audioPlayerViewPlayFromIcecastSelected:(AudioPlayerView *)audioPlayerView
{
    NSURL* url = [NSURL URLWithString:@"http://shoutmedia.abc.net.au:10326"];
    
    STKDataSource* dataSource = [STKAudioPlayer dataSourceFromURL:url];
    
    [audioPlayer setDataSource:dataSource withQueueItemId:[[SampleQueueId alloc] initWithUrl:url andCount:0]];
}

-(void) audioPlayerViewQueueShortFileSelected:(AudioPlayerView*)audioPlayerView
{
    NSString* path = [[NSBundle mainBundle] pathForResource:@"airplane" ofType:@"aac"];
    NSURL* url = [NSURL fileURLWithPath:path];
    
    STKDataSource* dataSource = [STKAudioPlayer dataSourceFromURL:url];
    
    [audioPlayer queueDataSource:dataSource withQueueItemId:[[SampleQueueId alloc] initWithUrl:url andCount:0]];
}

-(void) audioPlayerViewPlayFromLocalFileSelected:(AudioPlayerView*)audioPlayerView
{
    NSString* path = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"m4a"];
    NSURL* url = [NSURL fileURLWithPath:path];
    
    STKDataSource* dataSource = [STKAudioPlayer dataSourceFromURL:url];
    
    [audioPlayer setDataSource:dataSource withQueueItemId:[[SampleQueueId alloc] initWithUrl:url andCount:0]];
}

-(void) audioPlayerViewQueuePcmWaveFileSelected:(AudioPlayerView*)audioPlayerView
{
    NSURL* url = [NSURL URLWithString:@"http://www.abstractpath.com/files/audiosamples/perfectly.wav"];
    
    STKDataSource* dataSource = [STKAudioPlayer dataSourceFromURL:url];
    
    [audioPlayer queueDataSource:dataSource withQueueItemId:[[SampleQueueId alloc] initWithUrl:url andCount:0]];
}



@end
