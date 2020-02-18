//
//  AudioFileWriter.h
//  AudioGraph-iOS
//
//  Created by yxibng on 2020/2/16.
//  Copyright © 2020 姚晓丙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
NS_ASSUME_NONNULL_BEGIN


@interface AudioFileWriter : NSObject

- (instancetype)initWithInStreamDesc:(AudioStreamBasicDescription)inStreamDesc;

- (void)start;
- (void)writeWithAudioBufferList:(AudioBufferList *)audioBufferList inNumberFrames:(UInt32)inNumberFrames;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
