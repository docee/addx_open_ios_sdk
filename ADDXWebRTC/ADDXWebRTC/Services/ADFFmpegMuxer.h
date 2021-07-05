//
//  ADFFmpegMuxer.h
//  WebRTC-Demo
//
//  Created by Hao Shen on 6/9/20.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KMMedia.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ADFFmpegMuxerDelegate <NSObject>

@optional
- (void)ts2Mp4Result:(KMMediaAssetExportSessionStatus) status outputPath: (NSString *) outputfilePath;

@end

@interface ADFFmpegMuxer : NSObject

+ (instancetype)sharedInstance;

+ (BOOL)muxerMP4File:(NSString *)mp4file withH264File:(NSString *)h264File codecName:(NSString *)codecName;
// 转换Mp4视频
+ (BOOL)turnMp4Video:(NSString *)inputPath outputPath:(NSString *)outputPath;

// TS转换Mp4视频
- (BOOL)ts2Mp4:(NSString *)inputPath outputPath:(NSString *)outputPath;

// 代理
@property(nonatomic, weak) id<ADFFmpegMuxerDelegate> adFFmpegMuxerDelegate;

@end

NS_ASSUME_NONNULL_END
