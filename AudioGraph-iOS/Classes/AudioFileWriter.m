//
//  AudioFileWriter.m
//  AudioGraph-iOS
//
//  Created by yxibng on 2020/2/16.
//  Copyright © 2020 姚晓丙. All rights reserved.
//

#import "AudioFileWriter.h"
#import <AudioToolbox/AudioToolbox.h>
#import "AudioConfig.h"

typedef struct {
    CFURLRef fileURL;
    AudioFileTypeID audioFileTypeID;
    ExtAudioFileRef extAudioFileRef;
    AudioStreamBasicDescription inStreamDesc;
    AudioStreamBasicDescription clientStreamDesc;
    BOOL closed;
} AudioFileInfo;


@interface AudioFileWriter ()

@property (nonatomic) AudioFileInfo audioFileInfo;

@end


@implementation AudioFileWriter


- (instancetype)initWithInStreamDesc:(AudioStreamBasicDescription)inStreamDesc
{
    if (self = [super init]) {
        _audioFileInfo.clientStreamDesc = inStreamDesc;
        _audioFileInfo.audioFileTypeID = kAudioFileM4AType;
        _audioFileInfo.fileURL = (__bridge CFURLRef)([NSURL URLWithString:[AudioConfig m4aPath]]);
    }
    return self;
}


- (void)creatFile
{
    _audioFileInfo.inStreamDesc.mFormatID = kAudioFormatMPEG4AAC;
    _audioFileInfo.inStreamDesc.mChannelsPerFrame = _audioFileInfo.clientStreamDesc.mChannelsPerFrame;
    _audioFileInfo.inStreamDesc.mSampleRate = _audioFileInfo.clientStreamDesc.mSampleRate;


    UInt32 propSize = sizeof(self.audioFileInfo.inStreamDesc);
    OSStatus status = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo,
                                             0,
                                             NULL,
                                             &propSize,
                                             &_audioFileInfo.inStreamDesc);
    assert(status == noErr);
    if (status) {
        return;
    }

    status = ExtAudioFileCreateWithURL(_audioFileInfo.fileURL,
                                       _audioFileInfo.audioFileTypeID,
                                       &_audioFileInfo.inStreamDesc,
                                       NULL,
                                       kAudioFileFlags_EraseFile,
                                       &_audioFileInfo.extAudioFileRef);


    assert(status == noErr);
    if (status) {
        return;
    }

    status = ExtAudioFileSetProperty(_audioFileInfo.extAudioFileRef,
                                     kExtAudioFileProperty_ClientDataFormat,
                                     propSize,
                                     &_audioFileInfo.clientStreamDesc);
    assert(status == noErr);
    if (status) {
        return;
    }

    _audioFileInfo.closed = NO;
}


- (void)start
{
    [self creatFile];
}

- (void)writeWithAudioBufferList:(AudioBufferList *)audioBufferList inNumberFrames:(UInt32)inNumberFrames
{
    if (!audioBufferList) {
        return;
    }

    if (_audioFileInfo.closed) {
        return;
    }

    OSStatus status = ExtAudioFileWriteAsync(_audioFileInfo.extAudioFileRef, inNumberFrames, audioBufferList);
    assert(status == noErr);
    if (status) {
        return;
    }
}


- (void)stop
{
    ExtAudioFileDispose(_audioFileInfo.extAudioFileRef);
    _audioFileInfo.extAudioFileRef = NULL;

    _audioFileInfo.closed = YES;
}


@end
