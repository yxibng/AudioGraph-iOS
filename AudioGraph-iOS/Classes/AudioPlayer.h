//
//  AudioPlayer.h
//  AudioGraph-iOS
//
//  Created by yxibng on 2020/2/16.
//  Copyright © 2020 姚晓丙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioConfig.h"


NS_ASSUME_NONNULL_BEGIN

@class AudioPlayer;

@protocol AudioPlayerDelegate <NSObject>


@optional

- (void)audioPlayerDidStart:(AudioPlayer *)player;
- (void)audioPlayer:(AudioPlayer *)play fillAudioBufferList:(AudioBufferList *)audioBufferList inNumberFrames:(UInt32)inNumberFrames;
- (void)audioPlayerDidStop:(AudioPlayer *)player;

@end


@interface AudioPlayer : NSObject

@property (nonatomic, weak) id<AudioPlayerDelegate> delegate;

@property (nonatomic, readonly) AudioStreamBasicDescription playFormat;


- (instancetype)initWithAudioConfig:(AudioConfig *)config delegate:(id<AudioPlayerDelegate>)delegate;
- (void)start;
- (void)stop;
- (BOOL)isRunning;
@end

NS_ASSUME_NONNULL_END
