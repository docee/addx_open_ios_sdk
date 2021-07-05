//
//  LFSendeHelper.m
//  LFLiveKit
//
//  Created by kzhi on 2020/3/17.
//

#import "LFSendeHelper.h"
#import "LFStreamSocket.h"
#import "LFStreamRTMPSocket.h"
#import "EasyPusherAPI.h"
#include <pthread.h>
#import "LFHardwareAudioEncoder.h"

//#define DUMP_AUDIO 1
#ifdef DUMP_AUDIO
static FILE *aac_fp  = NULL;
#endif

static LFSendeHelper * sendeHelper = nil;
@interface LFSendeHelper()<LFStreamSocketDelegate,LFAudioEncodingDelegate> {
    pthread_mutex_t releaseLock;

}

/// 上传
@property (nonatomic, strong) id<LFStreamSocket> socket;
/// 流信息
@property (nonatomic, strong) LFLiveStreamInfo *streamInfo;
/// 音频编码
@property (nonatomic, strong) id<LFAudioEncoding> audioEncoder;
/// 音视频是否对齐
@property (nonatomic, assign) BOOL AVAlignment;
/// 时间戳锁
@property (nonatomic, strong) dispatch_semaphore_t lock;
/// 是否开始上传
@property (nonatomic, assign) BOOL uploading;
/// 当前是否采集到了音频
@property (nonatomic, assign) BOOL hasCaptureAudio;
/// 当前状态
@property (nonatomic, assign, readwrite) LFLiveState state;

@property (nonatomic) Easy_Handle handle;

#pragma mark -- 内部标识
/// 调试信息
@property (nonatomic, strong) LFLiveDebug *debugInfo;

@end

@implementation LFSendeHelper

- (instancetype)init{
    if (self = [super init]) {
        sendeHelper = self;
    }
    return self;
}

- (id<LFStreamSocket>)socket {
    if (!_socket) {
        _socket = [[LFStreamRTMPSocket alloc] initWithStream:self.streamInfo reconnectInterval:self.reconnectInterval reconnectCount:self.reconnectCount];
        [_socket setDelegate:self];
    }
    return _socket;
}

- (LFLiveStreamInfo *)streamInfo {
    if (!_streamInfo) {
        _streamInfo = [[LFLiveStreamInfo alloc] init];
    }
    return _streamInfo;
}

- (void)startLive:(nonnull LFLiveStreamInfo *)streamInfo {
    if (!streamInfo) return;
    _streamInfo = streamInfo;
    
    if (_streamInfo.audioConfiguration.sendProtcol == LFLiveSendProtcol_RTSP) {
        [self loadEasyPush:streamInfo];
    } else {
        _audioEncoder = [[LFHardwareAudioEncoder alloc] initWithAudioStreamConfiguration:streamInfo.audioConfiguration];
        [_audioEncoder setDelegate:self];
        [self.socket start];
    }
        
#ifdef DUMP_AUDIO
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writablePath;
    if (_streamInfo.audioConfiguration.sendProtcol == LFLiveSendProtcol_RTSP) {
        writablePath = [documentsDirectory stringByAppendingPathComponent:@"g1_audio.aac"];
    } else {
        writablePath = [documentsDirectory stringByAppendingPathComponent:@"g0_audio.pcm"];
    }
    NSString *fileAudioPath = writablePath;
    const char *path = [fileAudioPath cStringUsingEncoding:NSUTF8StringEncoding];
    if(aac_fp == NULL) {
        aac_fp = fopen(path, "wb");
    }
#endif
    NSLog(@"LFSendeHelper startLive");
}

- (void)encodeAudioData:(nullable NSData*)audioData timeStamp:(uint64_t)timeStamp {
    if (!self.uploading){
        return;
    }
    if (_streamInfo.audioConfiguration.sendProtcol == LFLiveSendProtcol_RTSP) {
        EASY_AV_Frame frame;
        frame.pBuffer = (void*)[audioData bytes];
        
        if (frame.pBuffer == NULL) {
            return;
        }

        frame.u32AVFrameLen = (Easy_U32)[audioData length];
        frame.u32VFrameType = EASY_SDK_AUDIO_CODEC_AAC;
        frame.u32AVFrameFlag = EASY_SDK_AUDIO_FRAME_FLAG;
        
        frame.u32TimestampSec= 0;//(Easy_U32)timestamp.value/timestamp.timescale;
        frame.u32TimestampUsec = 0;//timestamp.value%timestamp.timescale;
        
        
#ifdef DUMP_AUDIO
        if (aac_fp) {
            fwrite(frame.pBuffer, frame.u32AVFrameLen, 1, aac_fp);
        }
#endif
        int result = EasyPusher_PushFrame(self.handle, &frame);
        if (result != 0) {
            NSLog(@"------");
        }

    } else {
        [self.audioEncoder encodeAudioData:audioData timeStamp:timeStamp];
    }
}

- (void)loadEasyPush:(LFLiveStreamInfo *) streamInfo {
    if (self.handle) {
        return;
    }
    NSString * hostUrl = streamInfo.url;
    
    if (self.handle == NULL) {
        self.handle = EasyPusher_Create();
        assert(self.handle != NULL);
        EasyPusher_SetEventCallback(self.handle, easyPusher_Callback, 1, NULL);
    }
    
    EASY_MEDIA_INFO_T mediainfo;
    memset(&mediainfo, 0, sizeof(EASY_MEDIA_INFO_T));
    mediainfo.u32VideoFps = ~0; //~0只传音频
    
    
    mediainfo.u32AudioCodec = EASY_SDK_AUDIO_CODEC_AAC;// SDK output Audio PCMA
    mediainfo.u32AudioSamplerate = (int)streamInfo.audioConfiguration.audioSampleRate;
    mediainfo.u32AudioChannel = streamInfo.audioConfiguration.numberOfChannels;
    mediainfo.u32AudioBitsPerSample = streamInfo.audioConfiguration.audioBitrate;
    
    // 解析推流地址（例如hostUrl：rtsp://cloud.easydarwin.org:554/404802.sdp）
    NSString *cutIp = @"";
    int cutPort = 0;
    NSString *cutName = @"";
    
    @try {
        NSURL * url = [NSURL URLWithString:hostUrl];
        NSLog(@"A4xIJKPlayerViewModel net videoSpeakAction：%@", url );

        if (url.host == nil) {
            NSLog(@"解析流地址出错：url.host == nil");
            return;
        }
        cutIp = url.host;
        if (url.port == nil) {
            cutPort = 554;
        }else {
            cutPort = [url.port intValue];
        }
        if (url.path == nil) {
            NSLog(@"url.path == nil");
        }else {
            cutName = url.path;
        }
    } @catch (NSException *e) {
        NSLog(@"解析流地址出错：%@", e);
    }
    
    // ip地址
    const char *exprIp = [cutIp UTF8String];
    char *ip = malloc(strlen(exprIp)+1);
    strcpy(ip, exprIp);
    
    // name
    NSString *nameString = [cutName copy];
    const char *exName = [nameString cStringUsingEncoding:NSUTF8StringEncoding];
    char *name = malloc(strlen(exName)+1);
    strcpy(name, exName);
    
    EasyPusher_StartStream(self.handle,
                           ip, cutPort, name,
                           EASY_RTP_OVER_TCP,
                           NULL, NULL,
                           &mediainfo,
                           1024,
                           false);//1M缓冲区
    free(ip);
    free(name);

    
}

#pragma mark - 连接状态回调

int easyPusher_Callback(int _id, EASY_PUSH_STATE_T _state, EASY_AV_Frame *_frame, void *_userptr) {
    if (_state == EASY_PUSH_STATE_CONNECTING) {
        [sendeHelper connectStart];
        NSLog(@"EASY_PUSH_STATE_CONNECTING");
    } else if (_state == EASY_PUSH_STATE_CONNECTED) {
        [sendeHelper connectScuess];
        NSLog(@"EASY_PUSH_STATE_CONNECTED");
    } else if (_state == EASY_PUSH_STATE_CONNECT_FAILED) {
        [sendeHelper connectFail];
        NSLog(@"EASY_PUSH_STATE_CONNECT_FAILED");
    } else if (_state == EASY_PUSH_STATE_CONNECT_ABORT) {
        [sendeHelper connectFail];
        NSLog(@"EASY_PUSH_STATE_CONNECT_ABORT");
    } else if (_state == EASY_PUSH_STATE_PUSHING) {
//        [sendeHelper connectFail];
        NSLog(@"EASY_PUSH_STATE_PUSHING type: %d len: %d, ts: %d.%d",
              _frame->u32VFrameType, _frame->u32AVFrameLen,
              _frame->u32TimestampSec, _frame->u32TimestampUsec);
    } else if (_state == EASY_PUSH_STATE_DISCONNECTED) {
        [sendeHelper connectStop];
        NSLog(@"EASY_PUSH_STATE_DISCONNECTED");
    }
    
    return 0;




}

/** The stop stream .*/
- (void)stopLive {
    self.uploading = NO;
    [_socket stop];
    _socket = nil;
    
    
    // EasyPusher_StopStream完成后，才能继续
    pthread_mutex_lock(&releaseLock);
    if (self.handle != NULL) {
        EasyPusher_StopStream(self.handle);
        EasyPusher_Release(self.handle);
    }
    _handle = NULL;
    
    pthread_mutex_unlock(&releaseLock);
    
#ifdef DUMP_AUDIO
    if (aac_fp) {
        fclose(aac_fp);
        aac_fp = NULL;
    }
#endif

}


- (dispatch_semaphore_t)lock{
    if(!_lock){
        _lock = dispatch_semaphore_create(1);
    }
    return _lock;
}

#pragma mark -- PrivateMethod
- (void)pushSendBuffer:(LFFrame*)frame{
    self.hasCaptureAudio = YES;
    if(self.relativeTimestamps == 0){
        self.relativeTimestamps = frame.timestamp;
    }
    frame.timestamp = [self uploadTimestamp:frame.timestamp];
#ifdef DUMP_AUDIO
    if (aac_fp) {
        fwrite(frame.data.bytes, frame.data.length, 1, aac_fp);
    }
#endif
     NSLog(@"rtmp PUSH len: %lu, ts: %llu",
           frame.data.length, frame.timestamp);
    [self.socket sendFrame:frame];
}

- (uint64_t)uploadTimestamp:(uint64_t)captureTimestamp{
    dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);
    uint64_t currentts = 0;
    currentts = captureTimestamp - self.relativeTimestamps;
    dispatch_semaphore_signal(self.lock);
    return currentts;
}

- (BOOL)AVAlignment{
    return YES;
}

#pragma mark -- ConnectState


- (void)connectStart {
    self.state = LFLivePending;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(liveSession:liveStateDidChange:)]) {
            [self.delegate liveSession:nil liveStateDidChange:LFLivePending];
        }
    });
}

- (void)connectScuess {
    if (!self.uploading) {
        self.hasCaptureAudio = NO;
        self.relativeTimestamps = 0;
        self.uploading = YES;
    }
    self.state = LFLiveStart;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(liveSession:liveStateDidChange:)]) {
            [self.delegate liveSession:nil liveStateDidChange:LFLiveStart];
            
        }
    });
}

- (void)connectFail {
    self.uploading = NO;
    self.state = LFLiveError;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(liveSession:liveStateDidChange:)]) {
            [self.delegate liveSession:nil liveStateDidChange:LFLiveError];
        }
    });
}


- (void)connectStop {
    self.uploading = NO;
    self.state = LFLiveStop;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(liveSession:liveStateDidChange:)]) {
            [self.delegate liveSession:nil liveStateDidChange:LFLiveStop];
        }
    });
}

- (void)sockeError:(LFLiveSocketErrorCode) code {
    self.state = LFLiveError;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(liveSession:errorCode:)]) {
            [self.delegate liveSession:nil errorCode:code];
        }
    });
}

#pragma mark -- LFStreamTcpSocketDelegate
- (void)socketStatus:(nullable id<LFStreamSocket>)socket status:(LFLiveState)status {
    NSLog(@"playerhelper LFLiveSession socketStatus %lu" , (unsigned long)status);
    if (status == LFLiveStart) {
        NSLog(@"RTMP_STATE_LFLiveStart");
        [self connectScuess];
    } else if(status == LFLiveStop || status == LFLiveError){
        NSLog(@"RTMP_STATE_LFLiveStop");
        [self connectStop];
    } else if(status == LFLiveError){
        NSLog(@"RTMP_STATE_LFLiveError");
        [self sockeError:LFLiveSocketError_ConnectSocket];
    } else if(status == LFLivePending){
        NSLog(@"RTMP_STATE_LFLivePending");
        [self connectStart];
    } else if (status == LFLiveReady) {
        NSLog(@"RTMP_STATE_LFLiveReady");
    } else if (status == LFLiveRefresh) {
        NSLog(@"RTMP_STATE_LFLiveRefresh");
    }

}

- (void)socketDidError:(nullable id<LFStreamSocket>)socket errorCode:(LFLiveSocketErrorCode)errorCode {
    [self sockeError:errorCode];
}

- (void)socketDebug:(nullable id<LFStreamSocket>)socket debugInfo:(nullable LFLiveDebug *)debugInfo {
    self.debugInfo = debugInfo;
    if (self.showDebugInfo) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(liveSession:debugInfo:)]) {
                [self.delegate liveSession:nil debugInfo:debugInfo];
            }
        });
    }
}

- (void)socketBufferStatus:(nullable id<LFStreamSocket>)socket status:(LFLiveBuffferState)status {
  
}


#pragma mark -- EncoderDelegate
- (void)audioEncoder:(nullable id<LFAudioEncoding>)encoder audioFrame:(nullable LFAudioFrame *)frame {
    ///<  时间戳对齐
    if (self.uploading){
        [self pushSendBuffer:frame];
    }
}
@end
