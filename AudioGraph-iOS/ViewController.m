//
//  ViewController.m
//  AudioGraph-iOS
//
//  Created by 姚晓丙 on 2020/2/10.
//  Copyright © 2020 姚晓丙. All rights reserved.
//

#import "ViewController.h"
#import "AudioCapture.h"
#import "AudioFileWriter.h"
#import "AudioSessionUtil.h"
#import <AVFoundation/AVFoundation.h>
#import "AudioPlayer.h"
#import "AudioFileReader.h"


@interface ViewController () <AudioCaptureDelegate, AudioPlayerDelegate>
@property (nonatomic, strong) AudioCapture *audioCapture;
@property (nonatomic, strong) AudioFileWriter *fileWriter;

@property (nonatomic, strong) AudioPlayer *audioPlayer;
@property (nonatomic, strong) AudioFileReader *fileReader;


@end


@implementation ViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[AVAudioSession sharedInstance] removeObserver:self forKeyPath:@"category"];
}


- (void)setupRecorder
{
    _audioCapture = [[AudioCapture alloc] initWithAudioConfig:[AudioConfig defaultAudioConfig] delegate:self];
    _fileWriter = [[AudioFileWriter alloc] initWithInStreamDesc:_audioCapture.captureFormat];
    [_fileWriter start];
}


- (void)setupPlayer
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"senorita" ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:path];

    _audioPlayer = [[AudioPlayer alloc] initWithAudioConfig:[AudioConfig defaultAudioConfig] delegate:self];
    _fileReader = [[AudioFileReader alloc] initWithFileURL:url clientFormat:_audioPlayer.playFormat];
    NSDictionary *metaData = [self.fileReader metaData];
    NSLog(@"metaData = %@", metaData);
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [AudioSessionUtil setAudioSessionPlayAndRecord];

    // Do any additional setup after loading the view.

    //    [self setupRecorder];

    [self setupPlayer];
    
    
    
    [[AVAudioSession sharedInstance] addObserver:self forKeyPath:@"category" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAudioServicesReset:)
                                                 name:AVAudioSessionMediaServicesWereResetNotification
                                               object:[AVAudioSession sharedInstance]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAudioSessionInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:[AVAudioSession sharedInstance]];


    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAudioSessionRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context {
    //监听category的变化

}


- (IBAction)startCapture:(id)sender
{
    [_audioCapture startCapture];
}

- (IBAction)stopCapture:(id)sender
{
    [_audioCapture stopCapture];
}

- (IBAction)startPlay:(id)sender
{
    [_audioPlayer start];
}
- (IBAction)stopPlay:(id)sender
{
    [_audioPlayer stop];
}

- (IBAction)routeToSpeaker:(id)sender {
    [AudioSessionUtil setRouteToSpeaker];
}

#pragma mark -
- (void)audioPlayerDidStart:(AudioPlayer *)player
{
}

- (void)audioPlayerDidStop:(AudioPlayer *)player
{
}

- (void)audioPlayer:(AudioPlayer *)play fillAudioBufferList:(AudioBufferList *)audioBufferList inNumberFrames:(UInt32)inNumberFrames
{
    BOOL eof = NO;
    UInt32 readFrames = 0;
    [_fileReader readFrames:inNumberFrames audioBufferList:audioBufferList bufferSize:&readFrames eof:&eof];
    if (eof) {
        [_audioPlayer stop];
    }
}


#pragma mark -


- (void)handleAudioServicesReset:(NSNotification *)notification
{
    [AudioSessionUtil setAudioSessionPlayAndRecord];

    [self.audioCapture handleMeidaServiesWereReset];
}


- (void)handleAudioSessionInterruption:(NSNotification *)notification
{
    int type = [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue];
    if (AVAudioSessionInterruptionTypeBegan == type) {
        [self.audioPlayer stop];
        [self.audioCapture stopCapture];
    } else if (AVAudioSessionInterruptionTypeEnded == type) {
        NSDictionary *userInfo = notification.userInfo;
        NSNumber *shouldResume = userInfo[AVAudioSessionInterruptionOptionKey];
        if (shouldResume.integerValue == AVAudioSessionInterruptionOptionShouldResume) {
            [self.audioPlayer start];
        }
        [self.audioCapture startCapture];
    }
}

- (void)handleAudioSessionRouteChange:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *reason = userInfo[AVAudioSessionRouteChangeReasonKey];
    for (AVAudioSessionPortDescription *output in [AVAudioSession sharedInstance].currentRoute.outputs) {
        NSLog(@"port = %@, type = %@",output.portName, output.portType);
        
        if ([output.portType isEqualToString:AVAudioSessionPortBuiltInSpeaker]) {
            NSLog(@"=========");
        }
        
    }
    return;
    
    
    
    switch (reason.integerValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            //new device connect
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            //old device disconenct
            {
                AVAudioSession *session = [AVAudioSession sharedInstance];
                BOOL peripheralConnect = NO;
                NSArray *types = @[
                    AVAudioSessionPortHDMI,
                    AVAudioSessionPortAirPlay,
                    AVAudioSessionPortBluetoothLE,
                    AVAudioSessionPortHeadphones,
                    AVAudioSessionPortBluetoothA2DP
                ];

                for (AVAudioSessionPortDescription *output in session.currentRoute.outputs) {
                    if ([types containsObject:output.portType]) {
                        peripheralConnect = YES;
                        break;
                    }
                }

                if (!peripheralConnect) {
                    //旧设备不可用的时候使用扬声器
                    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
                }
            }
            break;
        default:
            break;
    }
}


#pragma mark -
- (void)audioCapture:(AudioCapture *)capture didStartWithError:(NSError *)error
{
    NSLog(@"%s, %@", __FUNCTION__, error);
}

- (void)audioCapture:(AudioCapture *)capture didStopWithError:(NSError *)error
{
    NSLog(@"%s, %@", __FUNCTION__, error);
    [_fileWriter stop];
}

- (void)audioCapture:(AudioCapture *)capture didOccurError:(NSError *)error
{
    NSLog(@"%s, %@", __FUNCTION__, error);
}

- (void)audioCapture:(AudioCapture *)capture didCaptureAudioBufferList:(AudioBufferList *)audioBufferList frames:(UInt32)frames
{
    //    NSLog(@"%s", __FUNCTION__);
    [_fileWriter writeWithAudioBufferList:audioBufferList inNumberFrames:frames];
}

@end
