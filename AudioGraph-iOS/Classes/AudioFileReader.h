//
//  AudioFileReader.h
//  AudioGraph-iOS
//
//  Created by yxibng on 2020/2/16.
//  Copyright © 2020 姚晓丙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN


@interface AudioFileReader : NSObject

- (instancetype)initWithFileURL:(NSURL *)URL clientFormat:(AudioStreamBasicDescription)clientFormat;


- (void)start;
- (void)stop;

- (void)readFrames:(UInt32)frames
   audioBufferList:(AudioBufferList *)audioBufferList
        bufferSize:(UInt32 *)bufferSize
               eof:(BOOL *)eof;


@end

NS_ASSUME_NONNULL_END
