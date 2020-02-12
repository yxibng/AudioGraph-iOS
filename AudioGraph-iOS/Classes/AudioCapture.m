//
//  AudioCapture.m
//  AudioGraph-iOS
//
//  Created by 姚晓丙 on 2020/2/10.
//  Copyright © 2020 姚晓丙. All rights reserved.
//

#import "AudioCapture.h"
#import <AVFoundation/AVFoundation.h>
#import "AudioSessionUtil.h"
#import "AudioStreamFormatUtil.h"

#define kInputBus 1
#define kOutputBus 0



typedef struct {
    AudioUnit unit;
    AUNode node;
} AudioNodeInfo;

@interface AudioCapture ()
@property (nonatomic, strong) AudioConfig *config;
@property (nonatomic) AUGraph graph;
@property (nonatomic) AudioNodeInfo nodeInfo;
@property (nonatomic) AudioStreamBasicDescription captureFormat;
@property (nonatomic) AudioBufferList *audioBufferList;
@end

@implementation AudioCapture

- (void)dealloc
{
    if (_audioBufferList) {
        [AudioStreamFormatUtil freeAudioBufferList:_audioBufferList];
        _audioBufferList = NULL;
    }
    
    if (_graph) {
        AUGraphClose(_graph);
        AUGraphUninitialize(_graph);
        DisposeAUGraph(_graph);
        _graph = NULL;
    }
    
}


- (instancetype)initWithAudioConfig:(AudioConfig *)config delegate:(id<AudioCaptureDelegate>)delegate
{
    if (self = [super init]) {
        _config = config;
        _delegate = delegate;
        
        //设置session
        [AudioSessionUtil setAudioSessionRecord];
        //设置IO频率，越小，实时性越强
        [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:config.ioBufferDuration error:NULL];
        //设置采样率
        [[AVAudioSession sharedInstance] setPreferredSampleRate:config.sampleRate error:nil];
        //设置后打印实际的结果
        NSLog(@"ioBufferDuration = %f, sampleRate = %f",
              [AVAudioSession sharedInstance].IOBufferDuration,
              [AVAudioSession sharedInstance].sampleRate);
        
        //默认采样非交错类型
        _captureFormat = [AudioStreamFormatUtil intFormatWithNumberOfChannels:(UInt32)config.numberOfChannels
                                                                   sampleRate:config.sampleRate
                                                                isInterleaved:NO];
        [self setup];
    }
    return self;
}

- (void)trackSetupErrorWithFunc:(const char *)funcName line:(int)line status:(OSStatus)status {
    
    NSString *message = [NSString stringWithFormat:@"line %d,%s",line,funcName];
    NSError *error = [NSError errorWithDomain:AudioCaptureSetupErrorDomain
                                         code:AudioCaptureCoreAudioErrorCode
                                     userInfo:@{
                                         @"status":@(status),
                                         @"message":message
                                     }];
    
    if ([self.delegate respondsToSelector:@selector(audioCapture:didOccurError:)]) {
        [self.delegate audioCapture:self didOccurError:error];
    }
    
}


- (OSStatus)setup
{
    //Create graph
    OSStatus status = NewAUGraph(&_graph);
    NSAssert(status == noErr, @"NewAUGraph error, status %d", status);
    if (status != noErr) {
        [self trackSetupErrorWithFunc:__FUNCTION__ line:__LINE__ status:status];
        return status;
    }
    
    AudioComponentDescription componentDescripiton = {0};
    componentDescripiton.componentType = kAudioUnitType_Output;
    componentDescripiton.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    componentDescripiton.componentManufacturer = kAudioUnitManufacturer_Apple;
    componentDescripiton.componentFlags = 0;
    componentDescripiton.componentFlagsMask = 0;
    
    //add node
    status = AUGraphAddNode(_graph,
                            &componentDescripiton,
                            &_nodeInfo.node);
    NSAssert(status == noErr, @"AUGraphAddNode error, status %d", status);
    if (status != noErr) {
        [self trackSetupErrorWithFunc:__FUNCTION__ line:__LINE__ status:status];
        return status;
    }
    //open graph
    status = AUGraphOpen(_graph);
    NSAssert(status == noErr, @"AUGraphOpen error, status %d", status);
    if (status != noErr) {
        [self trackSetupErrorWithFunc:__FUNCTION__ line:__LINE__ status:status];
        return status;
    }
    //get unit
    status = AUGraphNodeInfo(_graph,
                             _nodeInfo.node,
                             &componentDescripiton,
                             &_nodeInfo.unit);
    NSAssert(status == noErr, @"AUGraphNodeInfo error, status %d", status);
    if (status != noErr) {
        [self trackSetupErrorWithFunc:__FUNCTION__ line:__LINE__ status:status];
        return status;
    }
    
    
    //打开录音的开关
    UInt32 inputEnableFlag = 1;
    status = AudioUnitSetProperty(_nodeInfo.unit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &inputEnableFlag,
                                  sizeof(inputEnableFlag));
    
    NSAssert(status == noErr, @"EnableIO error, status %d", status);
    if (status != noErr) {
        [self trackSetupErrorWithFunc:__FUNCTION__ line:__LINE__ status:status];
        return status;
    }
    
    //禁用播放的开关,不然就一支打印EXCEPTION (-1): ""
    UInt32 playEnableFlag = 0;
    status = AudioUnitSetProperty(_nodeInfo.unit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  kOutputBus,
                                  &playEnableFlag,
                                  sizeof(playEnableFlag));
    NSAssert(status == noErr, @"disable output error, status %d", status);
    if (status != noErr) {
        [self trackSetupErrorWithFunc:__FUNCTION__ line:__LINE__ status:status];
        return status;
    }
    
    //打开回声消除的开关
    UInt32 echoCancellation;
    UInt32 size = sizeof(echoCancellation);
    //0 代表开， 1 代表关
    echoCancellation = 0;
    status = AudioUnitSetProperty(_nodeInfo.unit,
                                  kAUVoiceIOProperty_BypassVoiceProcessing,
                                  kAudioUnitScope_Global,
                                  0,
                                  &echoCancellation,
                                  size);
    NSAssert(status == noErr, @"enable echo cancellation error, status %d", status);
    if (status != noErr) {
        [self trackSetupErrorWithFunc:__FUNCTION__ line:__LINE__ status:status];
        return status;
    }
    
    //设置录音数据的格式
    AudioStreamBasicDescription format = _captureFormat;
    status = AudioUnitSetProperty(_nodeInfo.unit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &format,
                                  sizeof(AudioStreamBasicDescription));
    NSAssert(status == noErr, @"set stream format error, status %d", status);
    if (status != noErr) {
        [self trackSetupErrorWithFunc:__FUNCTION__ line:__LINE__ status:status];
        return status;
    }
    
    
    //设置录音数据回调
    AURenderCallbackStruct input;
    input.inputProc = inputRenderCallback;
    input.inputProcRefCon = (__bridge void *)(self);
    status = AudioUnitSetProperty(_nodeInfo.unit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global,
                                  kInputBus,
                                  &input,
                                  sizeof(input));
    
    NSAssert(status == noErr, @"set input callback error, status %d", status);
    if (status != noErr) {
        [self trackSetupErrorWithFunc:__FUNCTION__ line:__LINE__ status:status];
        return status;
    }
    
    UInt32 maximumFramesPerSlice;
    UInt32 ioSize = sizeof(maximumFramesPerSlice);
    
    status = AudioUnitGetProperty(_nodeInfo.unit,
                                  kAudioUnitProperty_MaximumFramesPerSlice,
                                  kAudioUnitScope_Global,
                                  kOutputBus,
                                  &maximumFramesPerSlice,
                                  &ioSize);
    
    NSLog(@"maximumFramesPerSlice = %d",maximumFramesPerSlice);
    NSAssert(status == noErr, @"get kAudioUnitProperty_MaximumFramesPerSlice error, status %d", status);
    if (status != noErr) {
        [self trackSetupErrorWithFunc:__FUNCTION__ line:__LINE__ status:status];
        return status;
    }
    
    //create audiobuffer list
    _audioBufferList = [AudioStreamFormatUtil audioBufferListWithNumberOfFrames:maximumFramesPerSlice streamFormat:self.captureFormat];
    
    //audio graph initialize
    status = AUGraphInitialize(_graph);
    NSAssert(status == noErr, @"AUGraphInitialize error, status %d", status);
    if (status != noErr) {
        [self trackSetupErrorWithFunc:__FUNCTION__ line:__LINE__ status:status];
        return status;
    }
    
    return noErr;
}

#pragma mark -
- (void)startCapture
{
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            [self _startCapture];
        } else {
            //no permission, start failed
            NSError *error = [NSError errorWithDomain:AudioCaptureStartErrorDomain code:AudioCaptureNoPermissionErrorCode userInfo:nil];
            if ([self.delegate respondsToSelector:@selector(audioCapture:didStartWithError:)]) {
                [self.delegate audioCapture:self didStartWithError:error];
            }
        }
    }];
}

- (void)_startCapture{
    
    if ([self isRunning]) {
        if ([self.delegate respondsToSelector:@selector(audioCapture:didStartWithError:)]) {
            [self.delegate audioCapture:self didStartWithError:nil];
        }
        return;
    }
    OSStatus status = AUGraphStart(_graph);
    NSAssert(status == noErr, @"Error trying start graph, status %d", status);
    if (status) {
        NSError *error = [NSError errorWithDomain:AudioCaptureStartErrorDomain code:AudioCaptureCoreAudioErrorCode userInfo:@{@"status":@(status)}];
        if ([self.delegate respondsToSelector:@selector(audioCapture:didStartWithError:)]) {
            [self.delegate audioCapture:self didStartWithError:error];
        }
        return;
    } else {
        if ([self.delegate respondsToSelector:@selector(audioCapture:didStartWithError:)]) {
            [self.delegate audioCapture:self didStartWithError:nil];
        }
    }
}

- (void)stopCapture
{
    if (!_graph || ![self isRunning]) {
        if ([self.delegate respondsToSelector:@selector(audioCapture:didStartWithError:)]) {
            [self.delegate audioCapture:self didStopWithError:nil];
        }
        return;
    }
    
    OSStatus status = AUGraphStop(_graph);
    NSAssert(status == noErr, @"Error trying stop graph, status %d", status);
    if (status) {
        NSError *error = [NSError errorWithDomain:AudioCaptureStopErrorDomain code:AudioCaptureCoreAudioErrorCode userInfo:@{@"status":@(status)}];
        if ([self.delegate respondsToSelector:@selector(audioCapture:didStopWithError:)]) {
            [self.delegate audioCapture:self didStopWithError:error];
        }
        return;
    } else {
        if ([self.delegate respondsToSelector:@selector(audioCapture:didStopWithError:)]) {
            [self.delegate audioCapture:self didStopWithError:nil];
        }
    }
    
}


- (BOOL)isRunning
{
    if (_graph == NULL) {
        return NO;
    }
    Boolean isRunning = false;
    OSStatus status = AUGraphIsRunning(_graph, &isRunning);
    NSAssert(status == noErr, @"Error trying querying whether graph is running, status %d", status);
    if (status) {
        NSError *error = [NSError errorWithDomain:AudioCaptureQueryRunningErrorDomain code:AudioCaptureCoreAudioErrorCode userInfo:@{@"status":@(status)}];
        if ([self.delegate respondsToSelector:@selector(audioCapture:didOccurError:)]) {
            [self.delegate audioCapture:self didOccurError:error];
        }
        return NO;
    }
    return isRunning;
}

- (void)handleMeidaServiesWereReset
{
    AUGraphClose(_graph);
    AUGraphUninitialize(_graph);
    DisposeAUGraph(_graph);
    _graph = NULL;
    
    if (_audioBufferList) {
        [AudioStreamFormatUtil freeAudioBufferList:self.audioBufferList];
        _audioBufferList = NULL;
    }
    
    [self setup];
}

#pragma mark - 录音数据的回调
OSStatus inputRenderCallback(void *inRefCon,
                             AudioUnitRenderActionFlags *ioActionFlags,
                             const AudioTimeStamp *inTimeStamp,
                             UInt32 inBusNumber,
                             UInt32 inNumberFrames,
                             AudioBufferList *ioData)
{
    AudioCapture *recorder = (__bridge AudioCapture *)inRefCon;
    // a variable where we check the status
    
    if (!recorder) {
        return -1;
    }
        
    for (int i = 0; i < recorder.audioBufferList->mNumberBuffers; i++) {
         recorder.audioBufferList->mBuffers[i].mDataByteSize = inNumberFrames * recorder.captureFormat.mBytesPerFrame;
     }
    
    // render input and check for error
    OSStatus status = AudioUnitRender(recorder->_nodeInfo.unit,
                                      ioActionFlags,
                                      inTimeStamp,
                                      inBusNumber,
                                      inNumberFrames,
                                      recorder.audioBufferList);
    
    if (status == noErr) {
        if ([recorder.delegate respondsToSelector:@selector(audioCapture:didCaptureAudioBufferList:)]) {
            [recorder.delegate audioCapture:recorder didCaptureAudioBufferList:recorder.audioBufferList];
        }
    } else {
        //handle error
        NSError *error = [NSError errorWithDomain:AudioCaptureRenderErrorDomain code:AudioCaptureCoreAudioErrorCode userInfo:@{@"status":@(status)}];
        if ([recorder.delegate respondsToSelector:@selector(audioCapture:didOccurError:)]) {
            [recorder.delegate audioCapture:recorder didOccurError:error];
        }
        
    }
    
    return status;
}




@end
