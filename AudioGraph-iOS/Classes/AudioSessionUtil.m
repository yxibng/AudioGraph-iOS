
//
//  AudioSessionUtil.m
//  AudioGraph-iOS
//
//  Created by 姚晓丙 on 2020/2/10.
//  Copyright © 2020 姚晓丙. All rights reserved.
//

#import "AudioSessionUtil.h"
#import <AVFoundation/AVFoundation.h>

@implementation AudioSessionUtil
+ (BOOL)setAudioSessionPlayback
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL ok = YES;
    NSError *setCategoryError = nil;
    if (audioSession.category == AVAudioSessionCategoryPlayback) {
        return ok;
    }

    ok = [audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDuckOthers error:&setCategoryError];
    
    if (!ok) {
        NSLog(@"%s setCategoryError=%@", __PRETTY_FUNCTION__, setCategoryError);
    }
    
    ok = [audioSession setMode:AVAudioSessionModeMoviePlayback error:NULL];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:NULL];
    return ok;
}
+ (BOOL)setAudioSessionRecord
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL ok = YES;
    NSError *setCategoryError = nil;
    if (audioSession.category == AVAudioSessionCategoryRecord) {
        return ok;
    }

    ok = [audioSession setCategory:AVAudioSessionCategoryRecord error:&setCategoryError];

    if (!ok) {
        NSLog(@"%s setCategoryError=%@", __PRETTY_FUNCTION__, setCategoryError);
    }
    ok = [audioSession setMode:AVAudioSessionModeDefault error:NULL];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:NULL];
    return ok;
}
+ (BOOL)setAudioSessionPlayAndRecord
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL ok = YES;

    NSError *setCategoryError = nil;
    if (@available(iOS 11.0, *)) {
        ok = [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                                  mode:AVAudioSessionModeVideoChat
                               options:AVAudioSessionCategoryOptionMixWithOthers |
                               AVAudioSessionCategoryOptionAllowBluetooth |
                               AVAudioSessionCategoryOptionDefaultToSpeaker |
                               AVAudioSessionCategoryOptionAllowBluetoothA2DP |
                               AVAudioSessionCategoryOptionAllowAirPlay
                                 error:&setCategoryError];
    } else if (@available(iOS 10.0, *)) {
        ok = [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                           withOptions:AVAudioSessionCategoryOptionMixWithOthers |
                           AVAudioSessionCategoryOptionAllowBluetooth |
                           AVAudioSessionCategoryOptionDefaultToSpeaker |
                           AVAudioSessionCategoryOptionAllowBluetoothA2DP |
                           AVAudioSessionCategoryOptionAllowAirPlay
                                 error:&setCategoryError];
    } else {
        ok = [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                           withOptions:AVAudioSessionCategoryOptionMixWithOthers |
                           AVAudioSessionCategoryOptionAllowBluetooth |
                           AVAudioSessionCategoryOptionDefaultToSpeaker
                                 error:&setCategoryError];
    }

    if (!ok) {
        NSLog(@"%s setCategoryError=%@", __PRETTY_FUNCTION__, setCategoryError);
    }
    
    NSError *error = nil;
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    if (error) {
        NSLog(@"active audioSession %@, error = %@", audioSession, error);
    }
    return ok;
}

+ (BOOL)setRouteToSpeaker
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL ok = YES;

    NSError *error;
    if (audioSession.category == AVAudioSessionCategoryPlayAndRecord && ![self isHeadsetPluggedIn]) {
        ok = [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    }
    return ok;
}

+ (BOOL)isHeadsetPluggedIn
{
    AVAudioSessionRouteDescription *route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription *desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;

        if ([[desc portType] isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
            return YES;
        }
        if ([[desc portType] isEqualToString:AVAudioSessionPortBluetoothLE]) {
            return YES;
        }
        if ([[desc portType] isEqualToString:AVAudioSessionPortBluetoothHFP]) {
            return YES;
        }
    }
    return NO;
}
@end
