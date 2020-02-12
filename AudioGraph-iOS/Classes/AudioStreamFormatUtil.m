//
//  AudioStreamFormatUtil.m
//  AudioGraph-iOS
//
//  Created by 姚晓丙 on 2020/2/12.
//  Copyright © 2020 姚晓丙. All rights reserved.
//

#import "AudioStreamFormatUtil.h"

@implementation AudioStreamFormatUtil

+ (BOOL)isInterleaved:(AudioStreamBasicDescription)asbd
{
    return !(asbd.mFormatFlags & kAudioFormatFlagIsNonInterleaved);
}


+ (AudioStreamBasicDescription)floatFormatWithNumberOfChannels:(UInt32)channels
                                                    sampleRate:(float)sampleRate
                                                 isInterleaved:(BOOL)isInterleaved
{
    AudioStreamBasicDescription asbd;
    UInt32 floatByteSize = sizeof(float);
    asbd.mChannelsPerFrame = channels;
    asbd.mBitsPerChannel = 8 * floatByteSize;
    if (isInterleaved) {
        asbd.mBytesPerFrame = asbd.mChannelsPerFrame * floatByteSize;
    } else {
        asbd.mBytesPerFrame = floatByteSize;
    }

    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerPacket = asbd.mFramesPerPacket * asbd.mBytesPerFrame;

    if (isInterleaved) {
        asbd.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
    } else {
        asbd.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved;
    }

    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mSampleRate = sampleRate;
    asbd.mReserved = 0;
    return asbd;
}

+ (AudioStreamBasicDescription)intFormatWithNumberOfChannels:(UInt32)channels
                                                  sampleRate:(float)sampleRate
                                               isInterleaved:(BOOL)isInterleaved
{
    AudioStreamBasicDescription asbd;
    UInt32 byteSize = 2;
    asbd.mChannelsPerFrame = channels;
    asbd.mBitsPerChannel = 8 * byteSize;
    if (isInterleaved) {
        asbd.mBytesPerFrame = asbd.mChannelsPerFrame * byteSize;
    } else {
        asbd.mBytesPerFrame = byteSize;
    }

    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerPacket = asbd.mFramesPerPacket * asbd.mBytesPerFrame;

    if (isInterleaved) {
        asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    } else {
        asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved;
    }

    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mSampleRate = sampleRate;
    asbd.mReserved = 0;
    return asbd;
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



@end
