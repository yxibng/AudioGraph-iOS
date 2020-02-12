//
//  AudioConfig.m
//  AudioGraph-iOS
//
//  Created by 姚晓丙 on 2020/2/10.
//  Copyright © 2020 姚晓丙. All rights reserved.
//

#import "AudioConfig.h"

@implementation AudioConfig
+ (AudioConfig *)defaultAudioConfig
{
    AudioConfig *config = [AudioConfig new];
    config.sampleRate = 16000.0;
    config.numberOfChannels = 1;
    config.ioBufferDuration = 0.02;
    return config;
}
@end
