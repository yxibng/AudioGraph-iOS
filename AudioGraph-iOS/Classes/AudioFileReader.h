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

/*
 获取元数据,
 Provides a dictionary containing the metadata (ID3) tags that are included in the header for the audio file.
 Typically this contains stuff like artist, title, release year, etc.
 */
- (NSDictionary *)metaData;


- (void)start;
- (void)stop;

- (void)readFrames:(UInt32)frames
   audioBufferList:(AudioBufferList *)audioBufferList
        bufferSize:(UInt32 *)bufferSize
               eof:(BOOL *)eof;


@end

NS_ASSUME_NONNULL_END
