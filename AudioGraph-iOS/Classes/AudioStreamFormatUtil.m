//
//  AudioStreamFormatUtil.m
//  AudioGraph-iOS
//
//  Created by 姚晓丙 on 2020/2/12.
//  Copyright © 2020 姚晓丙. All rights reserved.
//

#import "AudioStreamFormatUtil.h"
#import <AVFoundation/AVFoundation.h>

@implementation AudioStreamFormatUtil

+ (BOOL)isInterleaved:(AudioStreamBasicDescription)asbd
{
    return !(asbd.mFormatFlags & kAudioFormatFlagIsNonInterleaved);
}

+ (BOOL)isFloatFormat:(AudioStreamBasicDescription)asbd
{
    return asbd.mFormatFlags & kAudioFormatFlagIsFloat;
}


+ (AudioStreamBasicDescription)floatFormatWithNumberOfChannels:(UInt32)channels
                                                    sampleRate:(float)sampleRate
                                                 isInterleaved:(BOOL)isInterleaved
{
    AVAudioFormat *format = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:sampleRate channels:channels interleaved:isInterleaved];
    AudioStreamBasicDescription desc = *format.streamDescription;
    format = nil;
    return desc;
}

+ (AudioStreamBasicDescription)intFormatWithNumberOfChannels:(UInt32)channels
                                                  sampleRate:(float)sampleRate
                                               isInterleaved:(BOOL)isInterleaved
{
    
    AVAudioFormat *format = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16 sampleRate:sampleRate channels:channels interleaved:isInterleaved];
    AudioStreamBasicDescription desc = *format.streamDescription;
    format = nil;
    return desc;
}

+ (AudioBufferList *)audioBufferListWithNumberOfFrames:(UInt32)frames
                                          streamFormat:(AudioStreamBasicDescription)asbd
{
    BOOL isInterleaved = [self isInterleaved:asbd];

    UInt32 typeSize = asbd.mBytesPerFrame;
    UInt32 channels = asbd.mChannelsPerFrame;

    unsigned nBuffers;
    unsigned bufferSize;
    unsigned channelsPerBuffer;
    if (isInterleaved) {
        nBuffers = 1;
        bufferSize = typeSize * frames * channels;
        channelsPerBuffer = channels;
    } else {
        nBuffers = channels;
        bufferSize = typeSize * frames;
        channelsPerBuffer = 1;
    }

    AudioBufferList *audioBufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList) + sizeof(AudioBuffer) * (channels - 1));
    audioBufferList->mNumberBuffers = nBuffers;
    for (unsigned i = 0; i < nBuffers; i++) {
        audioBufferList->mBuffers[i].mNumberChannels = channelsPerBuffer;
        audioBufferList->mBuffers[i].mDataByteSize = bufferSize;
        audioBufferList->mBuffers[i].mData = calloc(bufferSize, 1);
    }
    return audioBufferList;
}

+ (void)freeAudioBufferList:(AudioBufferList *)bufferList
{
    if (bufferList) {
        if (bufferList->mNumberBuffers) {
            for (int i = 0; i < bufferList->mNumberBuffers; i++) {
                if (bufferList->mBuffers[i].mData) {
                    free(bufferList->mBuffers[i].mData);
                }
            }
        }
        free(bufferList);
    }
    bufferList = NULL;
}

+ (NSString *)stringForAudioStreamBasicDescription:(AudioStreamBasicDescription)asbd
{
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig(asbd.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
    return [NSString stringWithFormat:
            @"\nSample Rate:       %10.0f,\n"
            @"Format ID:           %10s,\n"
            @"Format Flags:        %10X,\n"
            @"Bytes per Packet:    %10d,\n"
            @"Frames per Packet:   %10d,\n"
            @"Bytes per Frame:     %10d,\n"
            @"Channels per Frame:  %10d,\n"
            @"Bits per Channel:    %10d,\n"
            @"IsInterleaved:       %i,\n"
            @"IsFloat:             %i,",
            asbd.mSampleRate,
            formatIDString,
            (unsigned int)asbd.mFormatFlags,
            (unsigned int)asbd.mBytesPerPacket,
            (unsigned int)asbd.mFramesPerPacket,
            (unsigned int)asbd.mBytesPerFrame,
            (unsigned int)asbd.mChannelsPerFrame,
            (unsigned int)asbd.mBitsPerChannel,
            [self isInterleaved:asbd],
            [self isFloatFormat:asbd]];
}
@end
