//
//  AudioSessionUtil.h
//  AudioGraph-iOS
//
//  Created by 姚晓丙 on 2020/2/10.
//  Copyright © 2020 姚晓丙. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioSessionUtil : NSObject

+ (BOOL)setAudioSessionPlayback;

+ (BOOL)setAudioSessionPlayAndRecord;

+ (BOOL)setAudioSessionRecord;

+ (BOOL)setRouteToSpeaker;

@end

NS_ASSUME_NONNULL_END
