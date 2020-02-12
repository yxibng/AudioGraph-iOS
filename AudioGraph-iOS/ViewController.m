//
//  ViewController.m
//  AudioGraph-iOS
//
//  Created by 姚晓丙 on 2020/2/10.
//  Copyright © 2020 姚晓丙. All rights reserved.
//

#import "ViewController.h"
#import "AudioCapture.h"

@interface ViewController ()<AudioCaptureDelegate>
@property (nonatomic, strong) AudioCapture *audioCapture;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _audioCapture = [[AudioCapture alloc] initWithAudioConfig:[AudioConfig defaultAudioConfig] delegate:self];
}
- (IBAction)startCapture:(id)sender {
    [_audioCapture startCapture];
}

- (IBAction)stopCapture:(id)sender {
    [_audioCapture stopCapture];
}



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
