//
//  AudioStreamFormatUtil.h
//  AudioGraph-iOS
//
//  Created by 姚晓丙 on 2020/2/12.
//  Copyright © 2020 姚晓丙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioStreamFormatUtil : NSObject


+ (BOOL)isInterleaved:(AudioStreamBasicDescription)asbd;

+ (BOOL)isFloatFormat:(AudioStreamBasicDescription)asbd;

/// 创建一个float 类型的音频描述
/// @param channels 声道数目： 1 单声道  2 双声道
/// @param sampleRate 采样率HZ ， 如 16000，44100
/// @param isInterleaved 是否是交错类型
+ (AudioStreamBasicDescription)floatFormatWithNumberOfChannels:(UInt32)channels
                                                    sampleRate:(float)sampleRate
                                                 isInterleaved:(BOOL)isInterleaved;


/// 创建一个sing int 类型的音频描述
/// @param channels 声道数目： 1 单声道  2 双声道
/// @param sampleRate 采样率HZ ， 如 16000，44100
/// @param isInterleaved 是否是交错类型
+ (AudioStreamBasicDescription)intFormatWithNumberOfChannels:(UInt32)channels
                                                  sampleRate:(float)sampleRate
                                               isInterleaved:(BOOL)isInterleaved;


/// 创建AudioBufferList， 使用完成后需要调用 `freeAudioBufferList:`来释放
/// @param frames AudioBufferList包含的帧数
/// @param asbd AudioStreamBasicDescription流描述
+ (AudioBufferList *)audioBufferListWithNumberOfFrames:(UInt32)frames
                                          streamFormat:(AudioStreamBasicDescription)asbd;

/// 释放AudioBufferList
/// @param bufferList 需要释放的AudioBufferList
+ (void)freeAudioBufferList:(AudioBufferList *)bufferList;


+ (NSString *)stringForAudioStreamBasicDescription:(AudioStreamBasicDescription)asbd;

@end

NS_ASSUME_NONNULL_END
