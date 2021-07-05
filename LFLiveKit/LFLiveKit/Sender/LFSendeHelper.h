//
//  LFSendeHelper.h
//  LFLiveKit
//
//  Created by kzhi on 2020/3/17.
//

#import <Foundation/Foundation.h>
#import "LFLiveAudioConfiguration.h"
#import "LFLiveStreamInfo.h"
#import "LFFrame.h"
#import "LFLiveSession.h"

NS_ASSUME_NONNULL_BEGIN

@interface LFSendeHelper : NSObject
@property (nullable, nonatomic, strong, readonly) LFLiveStreamInfo *streamInfo;
/** The reconnectCount control reconnect count (重连次数) *.*/
@property (nonatomic, assign) NSUInteger reconnectCount;

/** The delegate of the capture. captureData callback */
@property (nullable, nonatomic, weak) id<LFLiveSessionDelegate> delegate;
@property (nonatomic, assign) BOOL adaptiveBitrate;
/** The status of the stream .*/
@property (nonatomic, assign, readonly) LFLiveState state;
/// 是否开始上传
@property (nonatomic, assign, readonly) BOOL uploading;
/// 上传相对时间戳
@property (nonatomic, assign) uint64_t relativeTimestamps;
@property (nonatomic, assign) NSUInteger reconnectInterval;

/** The showDebugInfo control streamInfo and uploadInfo(1s) *.*/
@property (nonatomic, assign) BOOL showDebugInfo;
- (instancetype)init;

/** The start stream .*/
- (void)startLive:(nonnull LFLiveStreamInfo *)streamInfo;

/** The stop stream .*/
- (void)stopLive;


- (void)encodeAudioData:(nullable NSData*)audioData timeStamp:(uint64_t)timeStamp;

@end

NS_ASSUME_NONNULL_END
