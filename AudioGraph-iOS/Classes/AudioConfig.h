//
//  AudioConfig.h
//  AudioGraph-iOS
//
//  Created by 姚晓丙 on 2020/2/10.
//  Copyright © 2020 姚晓丙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

#define kInputBus 1
#define kOutputBus 0


typedef struct {
    AudioUnit unit;
    AUNode node;
} AudioNodeInfo;


@interface AudioConfig : NSObject

/// 目标采样采样率 HZ
@property (nonatomic, assign) double sampleRate;

/// 目标声道数量
@property (nonatomic, assign) NSUInteger numberOfChannels;

/// 单位秒
@property (nonatomic, assign) double ioBufferDuration;


+ (AudioConfig *)defaultAudioConfig;

@end


@interface AudioConfig (AudioFilePath)
+ (NSString *)m4aPath;

@end


NS_ASSUME_NONNULL_END
