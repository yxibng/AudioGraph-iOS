//
//  AudioCapture.h
//  AudioGraph-iOS
//
//  Created by 姚晓丙 on 2020/2/10.
//  Copyright © 2020 姚晓丙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioConfig.h"
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *AudioCaptureSetupErrorDomain = @"com.audiocapture.error.setup";
static NSString *AudioCaptureStartErrorDomain = @"com.audiocapture.error.start";
static NSString *AudioCaptureQueryRunningErrorDomain = @"com.audiocapture.error.queryRunning";
static NSString *AudioCaptureRenderErrorDomain = @"com.audiocapture.error.render";
static NSString *AudioCaptureStopErrorDomain = @"com.audiocapture.error.stop";


typedef NS_ENUM(NSUInteger, AudioCaptureErrorCode) {
    //调用AudioToolBox api产生了错误
    AudioCaptureCoreAudioErrorCode = 1100,
    //无权限录制错误
    AudioCaptureNoPermissionErrorCode = 1101
};


@class AudioCapture;
@protocol AudioCaptureDelegate<NSObject>
@optional


/// setup 错误， 运行错误回调
/// @param capture AudioCapture
/// @param error 运行中错误信息，userInfo 里面包含了OSStatus 错误码
- (void)audioCapture:(AudioCapture *)capture didOccurError:(NSError *_Nonnull)error;


/// 调用start结果回调
/// @param capture AudioCapture
/// @param error 正常开始 error = nil, 开启失败，包含错误信息
- (void)audioCapture:(AudioCapture *)capture didStartWithError:(NSError * _Nullable)error;


/// 调用stop结果回调
/// @param capture AudioCapture
/// @param error 正常结束error = nil, 否则包含错误信息
- (void)audioCapture:(AudioCapture *)capture didStopWithError:(NSError *_Nullable)error;


/// 录制的数据回调，每产生一次数据回调一次
/// @param capture AudioCapture
/// @param audioBufferList AudioBufferList
- (void)audioCapture:(AudioCapture *)capture didCaptureAudioBufferList:(AudioBufferList *)audioBufferList;

@end


@interface AudioCapture : NSObject

@property (nonatomic, weak) id<AudioCaptureDelegate>delegate;

- (instancetype)initWithAudioConfig:(AudioConfig *)config delegate:(id<AudioCaptureDelegate>)delegate;

- (void)startCapture;
- (void)stopCapture;
- (BOOL)isRunning;

- (void)handleMeidaServiesWereReset;
@end

NS_ASSUME_NONNULL_END
