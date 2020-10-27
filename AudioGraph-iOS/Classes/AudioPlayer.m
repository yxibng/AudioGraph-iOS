//
//  AudioPlayer.m
//  AudioGraph-iOS
//
//  Created by yxibng on 2020/2/16.
//  Copyright © 2020 姚晓丙. All rights reserved.
//

#import "AudioPlayer.h"
#import "AudioStreamFormatUtil.h"


@interface AudioPlayer ()

@property (nonatomic, strong) AudioConfig *config;
@property (nonatomic) AUGraph graph;
@property (nonatomic) AudioNodeInfo nodeInfo;
@property (nonatomic) AudioStreamBasicDescription playFormat;

@end


@implementation AudioPlayer

- (void)dealloc
{
    if (_graph) {
        AUGraphClose(_graph);
        AUGraphUninitialize(_graph);
        DisposeAUGraph(_graph);
        _graph = NULL;
    }
}


- (instancetype)initWithAudioConfig:(AudioConfig *)config delegate:(id<AudioPlayerDelegate>)delegate
{
    if (self = [super init]) {
        _config = config;
        _delegate = delegate;
        _playFormat = [AudioStreamFormatUtil intFormatWithNumberOfChannels:(UInt32)config.numberOfChannels sampleRate:config.sampleRate isInterleaved:NO];

        [self setup];
    }
    return self;
}

- (void)trackSetupErrorWithFunc:(const char *)funcName line:(int)line status:(OSStatus)status
{
    NSLog(@"%s, line = %d, status = %d", funcName, line, status);
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

    //设置播放数据的格式
    AudioStreamBasicDescription format = _playFormat;
    status = AudioUnitSetProperty(_nodeInfo.unit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &format,
                                  sizeof(AudioStreamBasicDescription));
    NSAssert(status == noErr, @"set stream format error, status %d", status);
    if (status != noErr) {
        [self trackSetupErrorWithFunc:__FUNCTION__ line:__LINE__ status:status];
        return status;
    }


    //设置播放拉取数据的回调

    AURenderCallbackStruct input;
    input.inputProc = playbackCallback;
    input.inputProcRefCon = (__bridge void *_Nullable)(self);
    status = AUGraphSetNodeInputCallback(self.graph, self.nodeInfo.node, kOutputBus, &input);
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

    NSLog(@"maximumFramesPerSlice = %d", maximumFramesPerSlice);
    NSAssert(status == noErr, @"get kAudioUnitProperty_MaximumFramesPerSlice error, status %d", status);
    if (status != noErr) {
        [self trackSetupErrorWithFunc:__FUNCTION__ line:__LINE__ status:status];
        return status;
    }

    //audio graph initialize
    status = AUGraphInitialize(_graph);
    NSAssert(status == noErr, @"AUGraphInitialize error, status %d", status);
    if (status != noErr) {
        [self trackSetupErrorWithFunc:__FUNCTION__ line:__LINE__ status:status];
        return status;
    }

    return noErr;
}


- (void)start
{
    if (!_graph || [self isRunning]) {
        return;
    }
    OSStatus status = AUGraphStart(_graph);
    NSAssert(status == noErr, @"Error trying start graph, status %d", status);
}

- (void)stop
{
    if (!_graph || ![self isRunning]) {
        return;
    }
    OSStatus status = AUGraphStop(_graph);
    NSAssert(status == noErr, @"Error trying stop graph, status %d", status);
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
        return NO;
    }
    return isRunning;
}


- (void)handleMeidaServiesWereReset {
    [self setup];
}

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData)
{
    AudioPlayer *player = (__bridge AudioPlayer *)(inRefCon);
    if (!player) {
        return noErr;
    }

    if ([player.delegate respondsToSelector:@selector(audioPlayer:fillAudioBufferList:inNumberFrames:)]) {
        [player.delegate audioPlayer:player fillAudioBufferList:ioData inNumberFrames:inNumberFrames];
    }

    return noErr;
}


@end
