//
//  ViewController.m
//  AudioGraph-iOS
//
//  Created by 姚晓丙 on 2020/2/10.
//  Copyright © 2020 姚晓丙. All rights reserved.
//

#import "ViewController.h"
#import "AudioCapture.h"
#import <AVFoundation/AVFoundation.h>


@interface ViewController () <AudioCaptureDelegate>
@property (nonatomic, strong) AudioCapture *audioCapture;
@end


@implementation ViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _audioCapture = [[AudioCapture alloc] initWithAudioConfig:[AudioConfig defaultAudioConfig] delegate:self];

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


- (IBAction)startCapture:(id)sender
{
    [_audioCapture startCapture];
}

- (IBAction)stopCapture:(id)sender
{
    [_audioCapture stopCapture];
}


#pragma mark -


- (void)handleAudioServicesReset:(NSNotification *)notification
{
    [self.audioCapture handleMeidaServiesWereReset];
}


- (void)handleAudioSessionInterruption:(NSNotification *)notification
{
    int type = [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue];
    if (AVAudioSessionInterruptionTypeBegan == type) {
        [self.audioCapture stopCapture];
    } else if (AVAudioSessionInterruptionTypeEnded == type) {
        NSDictionary *userInfo = notification.userInfo;
        NSNumber *shouldResume = userInfo[AVAudioSessionInterruptionOptionKey];
        if (shouldResume.integerValue == AVAudioSessionInterruptionOptionShouldResume) {
            [self.audioCapture startCapture];
        }
    }
}

- (void)handleAudioSessionRouteChange:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *reason = userInfo[AVAudioSessionRouteChangeReasonKey];

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
}

- (void)audioCapture:(AudioCapture *)capture didOccurError:(NSError *)error
{
    NSLog(@"%s, %@", __FUNCTION__, error);
}

- (void)audioCapture:(AudioCapture *)capture didCaptureAudioBufferList:(AudioBufferList *)audioBufferList
{
    NSLog(@"%s", __FUNCTION__);
}

@end
