//
//  LFAudioCapture.m
//  LFLiveKit
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//

#import "LFAudioCapture.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>
#import <opencore-amrnb/interf_enc.h>
#import "AACEncoder.h"

NSString *const LFAudioComponentFailedToCreateNotification = @"LFAudioComponentFailedToCreateNotification";

@interface LFAudioCapture ()

@property (nonatomic, assign) AudioComponentInstance componetInstance;
@property (nonatomic, assign) AudioComponent component;
@property (nonatomic, strong) dispatch_queue_t taskQueue;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, strong,nullable) LFLiveAudioConfiguration *configuration;

@end

@implementation LFAudioCapture

/* pointer to encoder state structure */
static void *enstate;
static const int PCM_BUFFER_SIZE = 160;
static short pcmBuffer[PCM_BUFFER_SIZE];
static int pcmBufferDataSize = 0;
static char silentByte[2] = {0,0};
static HANDLE_AACENCODER   m_aacEncHandle;
static uint8_t m_aacOutbuf[20480];
static int dtx;
#define DUMP_AUDIO 0
#ifdef DUMP_AUDIO
static FILE *fp_dumpAudio = NULL;
#endif
#define DUMP_AAC_AUDIO 1
#ifdef DUMP_AAC_AUDIO
static FILE *fp_dumpAudioAAC = NULL;
#endif
#define DUMP_PCM_AUDIO 0
#ifdef DUMP_PCM_AUDIO
static FILE *fp_dumpAudioPCM = NULL;
static char exeData[2];

#endif

#pragma mark -- LiftCycle
- (instancetype)initWithAudioConfiguration:(LFLiveAudioConfiguration *)configuration{
    if(self = [super init]){
        
        NSLog(@"playerhelper LFAudioCapture initWithAudioConfiguration in");
        
        _configuration = configuration;
        
        self.isRunning = NO;
        NSLog(@"playerhelper initWithAudioConfiguration");
        
        self.taskQueue = dispatch_queue_create("com.addx.audioCapture.Queue", NULL);
        
        AVAudioSession *session = [AVAudioSession sharedInstance];
        
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleRouteChange:)
                                                     name: AVAudioSessionRouteChangeNotification
                                                   object: session];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleInterruption:)
                                                     name: AVAudioSessionInterruptionNotification
                                                   object: session];
        
        AudioComponentDescription acd;
        acd.componentType = kAudioUnitType_Output;
        acd.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
        //acd.componentSubType = kAudioUnitSubType_RemoteIO;
        acd.componentManufacturer = kAudioUnitManufacturer_Apple;
        acd.componentFlags = 0;
        acd.componentFlagsMask = 0;
        
        self.component = AudioComponentFindNext(NULL, &acd);
        
        OSStatus status = noErr;
        status = AudioComponentInstanceNew(self.component, &_componetInstance);
        
        if (noErr != status) {
            [self handleAudioComponentCreationFailure];
        }
        
        UInt32 echoCancellation = 0;
        UInt32 size = sizeof(echoCancellation);
        
        AudioUnitSetProperty(self.componetInstance,
                             kAUVoiceIOProperty_BypassVoiceProcessing,
                             kAudioUnitScope_Global,
                             0,
                             &echoCancellation,
                             size);
        
        UInt32 flagOne = 1;
        
        AudioUnitSetProperty(self.componetInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flagOne, sizeof(flagOne));
        
        AudioStreamBasicDescription desc = {0};
        
        //pcm
         desc.mSampleRate = _configuration.audioSampleRate;
         desc.mFormatID = kAudioFormatLinearPCM;
         desc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
         desc.mChannelsPerFrame = (UInt32)_configuration.numberOfChannels;
         desc.mFramesPerPacket = 1;
         desc.mBitsPerChannel = 16;
         desc.mBytesPerFrame = desc.mBitsPerChannel / 8 * desc.mChannelsPerFrame;
         desc.mBytesPerPacket = desc.mBytesPerFrame * desc.mFramesPerPacket;
          

                if (aacEncOpen(&m_aacEncHandle, 0, desc.mChannelsPerFrame) != AACENC_OK) {
                printf("Unable to open fdkaac encoder\n");
                //return -1;
            }
         
            if (aacEncoder_SetParam(m_aacEncHandle, AACENC_AOT, 2) != AACENC_OK) {  //aac lc
                printf("Unable to set the AOT\n");
                //return -1;
            }
         
            if (aacEncoder_SetParam(m_aacEncHandle, AACENC_SAMPLERATE, desc.mSampleRate ) != AACENC_OK) {
                printf("Unable to set the AOT\n");
                //return -1;
            }
            if (aacEncoder_SetParam(m_aacEncHandle, AACENC_CHANNELMODE, MODE_1) != AACENC_OK) {  //2 channle
                printf("Unable to set the channel mode\n");
                //return -1;
            }
            if (aacEncoder_SetParam(m_aacEncHandle, AACENC_BITRATE, _configuration.audioBitrate) != AACENC_OK) {
                printf("Unable to set the bitrate\n");
                //return -1;
            }
            if (aacEncoder_SetParam(m_aacEncHandle, AACENC_TRANSMUX, 2) != AACENC_OK) { //0-raw 2-adts
                printf("Unable to set the ADTS transmux\n");
                //return -1;
            }
         
            if (aacEncEncode(m_aacEncHandle, NULL, NULL, NULL, NULL) != AACENC_OK) {
                printf("Unable to initialize the encoder\n");
                //return -1;
            }
         
            AACENC_InfoStruct info = { 0 };
            if (aacEncInfo(m_aacEncHandle, &info) != AACENC_OK) {
                printf("Unable to get the encoder info\n");
                //return -1;
            }
        
        AURenderCallbackStruct cb;
        cb.inputProcRefCon = (__bridge void *)(self);
        switch(_configuration.audioCodecType){
            case LFLiveAudioCodecType_PCM:
                cb.inputProc = handleInputBuffer;
                break;
            case LFLiveAudioCodecType_AMR:
                cb.inputProc = handleInputBufferAMR;
                break;
            case LFLiveAudioCodecType_AAC:
                if (self.configuration.sendProtcol == LFLiveSendProtcol_RTSP) {
                    cb.inputProc = handleInputBufferAAC;
                }
                break;
            default:
                cb.inputProc = handleInputBuffer;
        }
        AudioUnitSetProperty(self.componetInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &desc, sizeof(desc));
        AudioUnitSetProperty(self.componetInstance, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &cb, sizeof(cb));
        
        
        status = AudioUnitInitialize(self.componetInstance);
        
        if (noErr != status) {
            [self handleAudioComponentCreationFailure];
        }
        
        [session setPreferredSampleRate:_configuration.audioSampleRate error:nil];
        [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth |
         AVAudioSessionCategoryOptionDefaultToSpeaker |
         AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers
                       error:nil];
        [session setActive:YES withOptions:kAudioSessionSetActiveFlag_NotifyOthersOnDeactivation error:nil];
        
        if(_configuration.audioCodecType == LFLiveAudioCodecType_AMR)
            enstate = Encoder_Interface_init(dtx);
#if DUMP_AUDIO
        NSArray *cacPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachePath = [cacPath objectAtIndex:0];
        NSString *videoPath = [cachePath stringByAppendingPathComponent:@"audio_data.amr"];
        NSString *fileVideoPath = videoPath;
        const char *path = [fileVideoPath cStringUsingEncoding:NSUTF8StringEncoding];
        
        if(fp_dumpAudio == NULL) {
            fp_dumpAudio = fopen(path, "wb");
        }
#endif
#if DUMP_AAC_AUDIO
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *writablePath = [documentsDirectory stringByAppendingPathComponent:@"audio_data.aac"];
        NSString *fileAudioPath = writablePath;
        const char *path = [fileAudioPath cStringUsingEncoding:NSUTF8StringEncoding];
        if(fp_dumpAudioAAC == NULL) {
            fp_dumpAudioAAC = fopen(path, "wb");
        }
#endif
#if DUMP_PCM_AUDIO
                NSArray *paths1 = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory1 = [paths1 objectAtIndex:0];
                NSString *writablePath1 = [documentsDirectory1 stringByAppendingPathComponent:@"audio_data.pcm"];
                NSString *fileAudioPath1 = writablePath1;
                const char *path1 = [fileAudioPath1 cStringUsingEncoding:NSUTF8StringEncoding];
                if(fp_dumpAudioPCM == NULL) {
                    fp_dumpAudioPCM = fopen(path1, "wb");
            }
#endif
        
        NSLog(@"playerhelper LFAudioCapture initWithAudioConfiguration out");
    }
    return self;
}

- (void)updateConfig {
    NSLog(@"playerhelper LFAudioCapture updateConfig in");
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth |
                    AVAudioSessionCategoryOptionDefaultToSpeaker |
                    AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers
        error:nil];
    [session setActive:YES withOptions:kAudioSessionSetActiveFlag_NotifyOthersOnDeactivation error:nil];
    NSLog(@"playerhelper LFAudioCapture updateConfig out");
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"playerhelper LFAudioCapture dealloc in");

    dispatch_sync(self.taskQueue, ^{
        if (self.componetInstance) {
            NSLog(@"playerhelper LFAudioCapture real dealloc in");
            self.isRunning = NO;
            AudioOutputUnitStop(self.componetInstance);
            AudioUnitUninitialize(self.componetInstance);
            AudioComponentInstanceDispose(self.componetInstance);
            self.componetInstance = nil;
            self.component = nil;
            if(_configuration.audioCodecType == LFLiveAudioCodecType_AMR)
                Encoder_Interface_exit(enstate);
            
            aacEncClose(&m_aacEncHandle);
#if DUMP_AUDIO
            fclose(fp_dumpAudio);
            fp_dumpAudio = NULL;
#endif
#if DUMP_AAC_AUDIO
            fclose(fp_dumpAudioAAC);
            fp_dumpAudioAAC = NULL;
#endif

#if DUMP_PCM_AUDIO
            exeData[0] = _configuration.asc[0];
            exeData[1] = _configuration.asc[1];
            fclose(fp_dumpAudioPCM);
            fp_dumpAudioPCM = NULL;
#endif
            NSLog(@"playerhelper LFAudioCapture real dealloc out");
        }
    });
    NSLog(@"playerhelper LFAudioCapture dealloc out");
}

#pragma mark -- Setter
- (void)setRunning:(BOOL)running {
    NSLog(@"playerhelper MicrophoneSource: setRunning %d", running);
    if (running) {
        NSLog(@"playerhelper MicrophoneSource: startRunning");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth |
                        AVAudioSessionCategoryOptionDefaultToSpeaker |
                        AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers
            error:nil];
        NSError * error = nil;
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
    }
    
    
    if (_running == running) return;
    _running = running;
    if (_running) {
        dispatch_async(self.taskQueue, ^{
            self.isRunning = YES;
            OSStatus state = AudioOutputUnitStart(self.componetInstance);
            NSLog(@"playerhelper MicrophoneSource: startRunning state %d",state);

        });
    } else {
        dispatch_sync(self.taskQueue, ^{
            self.isRunning = NO;
            NSLog(@"playerhelper MicrophoneSource: stopRunning");
            AudioOutputUnitStop(self.componetInstance);
        });
    }
}

#pragma mark -- CustomMethod
- (void)handleAudioComponentCreationFailure {
    NSLog(@"playerhelper handleAudioComponentCreationFailure");
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:LFAudioComponentFailedToCreateNotification object:nil];
    });
}

#pragma mark -- NSNotification
- (void)handleRouteChange:(NSNotification *)notification {
    
    AVAudioSession *session = [ AVAudioSession sharedInstance ];
    NSString *seccReason = @"";
    NSInteger reason = [[[notification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    AVAudioSessionRouteDescription* prevRoute = [[notification userInfo] objectForKey:AVAudioSessionRouteChangePreviousRouteKey];
    switch (reason) {
    case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
        seccReason = @"The route changed because no suitable route is now available for the specified category.";
        break;
    case AVAudioSessionRouteChangeReasonWakeFromSleep:
        seccReason = @"The route changed when the device woke up from sleep.";
        break;
    case AVAudioSessionRouteChangeReasonOverride:
        seccReason = @"The output route was overridden by the app.";
        break;
    case AVAudioSessionRouteChangeReasonCategoryChange:
        seccReason = @"The category of the session object changed.";
        break;
    case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        seccReason = @"The previous audio output path is no longer available.";
        break;
    case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
        seccReason = @"A preferred new audio output path is now available.";
        break;
    case AVAudioSessionRouteChangeReasonUnknown:
    default:
        seccReason = @"The reason for the change is unknown.";
        break;
    }
    NSLog(@"playerhelper handleRouteChange reason is %@", seccReason);

    AVAudioSessionRouteDescription * routeDes =session.currentRoute;
    NSArray * routeInput=routeDes.inputs;
    
    for (AVAudioSessionPortDescription * port in routeInput) {
        NSLog(@"当前输入端口名 :%@  端口类型:%@",port.portName,port.portType);
    }
    NSArray * routeOutPut=routeDes.outputs;
    for (AVAudioSessionPortDescription * port in routeOutPut) {
        NSLog(@"当前输出端口名 :%@  端口类型:%@",port.portName,port.portType);
        
    }
    
//    AVAudioSessionPortDescription *input = [[session.currentRoute.inputs count] ? session.currentRoute.inputs : nil objectAtIndex:0];
//    if (input.portType == AVAudioSessionPortHeadsetMic) {
//
//    }
}

- (void)handleInterruption:(NSNotification *)notification {
    NSInteger reason = 0;
    NSString *reasonStr = @"";
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification]) {
        //Posted when an audio interruption occurs.
        reason = [[[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey] integerValue];
        if (reason == AVAudioSessionInterruptionTypeBegan) {
            if (self.isRunning) {
                dispatch_sync(self.taskQueue, ^{
                    NSLog(@"playerhelper MicrophoneSource: stopRunning");
                    AudioOutputUnitStop(self.componetInstance);
                });
            }
        }

        if (reason == AVAudioSessionInterruptionTypeEnded) {
            reasonStr = @"playerhelper AVAudioSessionInterruptionTypeEnded";
            NSNumber *seccondReason = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey];
            switch ([seccondReason integerValue]) {
            case AVAudioSessionInterruptionOptionShouldResume:
                if (self.isRunning) {
                    dispatch_async(self.taskQueue, ^{
                        NSLog(@"playerhelper MicrophoneSource: startRunning");
                        AudioOutputUnitStart(self.componetInstance);
                    });
                }
                // Indicates that the audio session is active and immediately ready to be used. Your app can resume the audio operation that was interrupted.
                break;
            default:
                break;
            }
        }

    }
    ;
    NSLog(@"handleInterruption: %@ reason %@", [notification name], reasonStr);
}

#pragma mark -- CallBack
static OSStatus handleInputBuffer(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    @autoreleasepool {
        LFAudioCapture *source = (__bridge LFAudioCapture *)inRefCon;
        if (!source) return -1;

        AudioBuffer buffer;
        buffer.mData = NULL;
        buffer.mDataByteSize = 0;
        buffer.mNumberChannels = 1;
        
        AudioBufferList buffers;
        buffers.mNumberBuffers = 1;
        buffers.mBuffers[0] = buffer;
        
        OSStatus status = AudioUnitRender(source.componetInstance,
                                          ioActionFlags,
                                          inTimeStamp,
                                          inBusNumber,
                                          inNumberFrames,
                                          &buffers);

        if (source.muted) {
            double lastSendTime = source.lastSendTime ;
            double currentTime = [[NSDate date] timeIntervalSince1970] ;
            if (currentTime - lastSendTime < 1) {
                return status;
            }
            source.lastSendTime = currentTime;
            for (int i = 0; i < buffers.mNumberBuffers; i++) {
                AudioBuffer ab = buffers.mBuffers[i];
                memset(ab.mData, 0, ab.mDataByteSize);
            }
        }
        if (!status) {
            if(source.muted){
                if (source.delegate && [source.delegate respondsToSelector:@selector(captureOutput:audioData:)]) {
                    // Send Empty Packet
                    // bugfix: send 128byte, if send 2bytes, will not send rtmp packet, after about 10s, wowza will unpublish this stream.
                    // send 128bytes, make sure send a rtmp packet, just for keep rtmp connect alive.
                    char buf[128] = {0};
                    //[source.delegate captureOutput:source audioData:[NSData dataWithBytes:silentByte length:sizeof(silentByte)]];
                    [source.delegate captureOutput:source audioData:[NSData dataWithBytes:buf length:sizeof(buf)]];
                }
            }else{
                if (source.delegate && [source.delegate respondsToSelector:@selector(captureOutput:audioData:)]) {
                    [source.delegate captureOutput:source audioData:[NSData dataWithBytes:buffers.mBuffers[0].mData length:buffers.mBuffers[0].mDataByteSize]];
                }
            }
            if(source.muted){
                if (source.delegate && [source.delegate respondsToSelector:@selector(captureOutput:audioVoiceNumber:)] ) {
                    //Send Empty Packet
                    NSMutableArray * bytes = [NSMutableArray new];
                    [bytes addObject:[NSNumber numberWithFloat:0.0f]];
                    [source.delegate captureOutput:source audioVoiceNumber:bytes] ;
                }
            }else{
                if (source.delegate && [source.delegate respondsToSelector:@selector(captureOutput:audioVoiceNumber:)] ) {
                    [source.delegate captureOutput:source audioVoiceNumber:[source getBufferVoice:buffers]] ;
                }
            }
          
        }
        return status;
    }
}


static OSStatus handleInputBufferAAC(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    @autoreleasepool {
        LFAudioCapture *source = (__bridge LFAudioCapture *)inRefCon;
        if (!source) return -1;
        
        Boolean sendEmpty = false;
        AudioBuffer buffer;
        buffer.mData = NULL;
        buffer.mDataByteSize = 0;
        buffer.mNumberChannels = 1;
        
        AudioBufferList buffers;
        buffers.mNumberBuffers = 1;
        buffers.mBuffers[0] = buffer;
        
        OSStatus status = AudioUnitRender(source.componetInstance,
                                          ioActionFlags,
                                          inTimeStamp,
                                          inBusNumber,
                                          inNumberFrames,
                                          &buffers);
        char* pData = buffers.mBuffers[0].mData;
        int size = buffers.mBuffers[0].mDataByteSize;

        if(source.muted){
            // send 16 bytes every 1 sec, compat with android.
            double lastSendTime = source.lastSendTime ;
            double currentTime = [[NSDate date] timeIntervalSince1970] ;
            if (currentTime - lastSendTime < 1) {
                return status;
            }
            source.lastSendTime = currentTime;
            sendEmpty = true;
            
            
            if (source.delegate && [source.delegate respondsToSelector:@selector(captureOutput:audioVoiceNumber:)] ) {
                //Send Empty Packet
                NSMutableArray * bytes = [[NSMutableArray alloc] initWithCapacity:80];
                for (int i = 0 ; i < 80 ; i ++ ){
                    [bytes addObject:[NSNumber numberWithFloat:0.0f]];
                }
                [source.delegate captureOutput:source audioVoiceNumber:bytes] ;
            }
            if (source.delegate && [source.delegate respondsToSelector:@selector(captureOutput:audioData:)]) {
                
                for (int i = 0; i < buffers.mNumberBuffers; i++) {
                    AudioBuffer ab = buffers.mBuffers[i];
                    memset(ab.mData, 0, ab.mDataByteSize);
                }
            }
        }else{
            if (source.delegate && [source.delegate respondsToSelector:@selector(captureOutput:audioVoiceNumber:)] ) {
                [source.delegate captureOutput:source audioVoiceNumber:[source getBufferVoice:buffers]] ;
            }
        }
        
        
        if (source.aacEncoder == nil ){
            source.aacEncoder = [[AACEncoder alloc] init];
        }
#if DUMP_PCM_AUDIO
        if(fp_dumpAudioPCM){
            fwrite(buffers.mBuffers[0].mData, 1, buffers.mBuffers[0].mDataByteSize, fp_dumpAudioPCM);
    }
#endif
        AACENC_BufDesc in_buf = { 0 }, out_buf = { 0 };
            AACENC_InArgs in_args = { 0 };
            AACENC_OutArgs out_args = { 0 };
            int in_identifier = IN_AUDIO_DATA;
            int in_elem_size = 2;
         
            in_args.numInSamples = size/2;  //size为pcm字节数
            in_buf.numBufs = 1;
            in_buf.bufs = (void **)&pData;  //pData为pcm数据指针
            in_buf.bufferIdentifiers = &in_identifier;
            in_buf.bufSizes = &size;
            in_buf.bufElSizes = &in_elem_size;
         
            int out_identifier = OUT_BITSTREAM_DATA;
            void *out_ptr = m_aacOutbuf;
            int out_size = sizeof(m_aacOutbuf);
            int out_elem_size = 1;
            out_buf.numBufs = 1;
            out_buf.bufs = &out_ptr;
            out_buf.bufferIdentifiers = &out_identifier;
            out_buf.bufSizes = &out_size;
            out_buf.bufElSizes = &out_elem_size;
        
        // send 16 bytes every 1sec, compat with android.
        UInt8 *emptyData = NULL;
        if (sendEmpty) {
            // if less than 1024 samples, encode will failed
            emptyData = (UInt8 *)malloc(2048);
            int emptyDataSize = 2048;
            memset(emptyData, 0, emptyDataSize);
            in_buf.bufs = (void **)&emptyData;
            in_buf.bufSizes = &emptyDataSize;
            in_args.numInSamples = emptyDataSize / 2;
        }
            
        if ((aacEncEncode(m_aacEncHandle, &in_buf, &out_buf, &in_args, &out_args)) != AACENC_OK) {
            NSLog(@"Encoding aac failed\n");
            //return NVSTITCH_ERROR_GENERAL;
        }
        
        // 16 bytes 0
        if (sendEmpty && out_args.numOutBytes >= 16) {
            out_args.numOutBytes = 16;
            // set to 0 for G1 device need this
            memset(m_aacOutbuf, 0, 16);
        }
        
        if (emptyData) {
            free(emptyData);
            emptyData = NULL;
        }

            //if (out_args.numOutBytes == 0)
                //NSLog(@"Encoding aac failed\n");
                //return NVSTITCH_ERROR_GENERAL;
            //fwrite(outbuf, 1, out_args.numOutBytes, out);
        
                       
        //NSTimeInterval dad = [NSDate date].timeIntervalSince1970;
        __weak typeof(source) weakSouce = source;
        
        if (out_args.numOutBytes)
        {
            #if DUMP_AAC_AUDIO
                            if(fp_dumpAudioAAC){
                                int rawDataLength = out_args.numOutBytes;
                                int adtsLength = 7;
                                char *packet = malloc(sizeof(char) * adtsLength);
                                // Variables Recycled by addADTStoPacket
                                int profile = 2;  //AAC LC
                                //39=MediaCodecInfo.CodecProfileLevel.AACObjectELD;
                                NSInteger freqIdx = 16000;  //44.1KHz
                                int chanCfg = (int)1;  //MPEG-4 Audio Channel Configuration. 1 Channel front-center
                                NSUInteger fullLength = adtsLength + rawDataLength;
                                // fill in ADTS data
                                packet[0] = (char)0xFF;     // 11111111     = syncword
                                packet[1] = (char)0xF9;     // 1111 1 00 1  = syncword MPEG-2 Layer CRC
                                packet[2] = (char)(((profile-1)<<6) + (freqIdx<<2) +(chanCfg>>2));
                                packet[3] = (char)(((chanCfg&3)<<6) + (fullLength>>11));
                                packet[4] = (char)((fullLength&0x7FF) >> 3);
                                packet[5] = (char)(((fullLength&7)<<5) + 0x1F);
                                packet[6] = (char)0xFC;
                                NSData *adtsdata = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
                                //fwrite(adtsdata.bytes, 1, adtsdata.length, fp_dumpAudioAAC);
                                fwrite((char*)m_aacOutbuf, 1, out_args.numOutBytes, fp_dumpAudioAAC);
                            }
            #endif
            [weakSouce.delegate captureOutput:weakSouce audioData:[NSData dataWithBytes:m_aacOutbuf
            length:out_args.numOutBytes]];
            
        }
//        if (source.muted) {
//            double lastSendTime = source.lastSendTime ;
//            double currentTime = [[NSDate date] timeIntervalSince1970] ;
//            if (currentTime - lastSendTime < 1) {
//                return status;
//            }
//            source.lastSendTime = currentTime;
//            for (int i = 0; i < buffers.mNumberBuffers; i++) {
//                AudioBuffer ab = buffers.mBuffers[i];
//                memset(ab.mData, 0, ab.mDataByteSize);
//            }
//        }
//        if (!status) {
//            if(source.muted){
//                if (source.delegate && [source.delegate respondsToSelector:@selector(captureOutput:audioData:)]) {
//                    //Send Empty Packet
//                    [source.delegate captureOutput:source audioData:[NSData dataWithBytes:silentByte length:sizeof(silentByte)]];
//                }
//            }else{
//                if (source.delegate && [source.delegate respondsToSelector:@selector(captureOutput:audioData:)]) {
//                    [source.delegate captureOutput:source audioData:[NSData dataWithBytes:buffers.mBuffers[0].mData length:buffers.mBuffers[0].mDataByteSize]];
//                }
//            }
//            if(source.muted){
//                if (source.delegate && [source.delegate respondsToSelector:@selector(captureOutput:audioVoiceNumber:)] ) {
//                    //Send Empty Packet
//                    NSMutableArray * bytes = [NSMutableArray new];
//                    [bytes addObject:[NSNumber numberWithFloat:0.0f]];
//                    [source.delegate captureOutput:source audioVoiceNumber:bytes] ;
//                }
//            }else{
//                if (source.delegate && [source.delegate respondsToSelector:@selector(captureOutput:audioVoiceNumber:)] ) {
//                    [source.delegate captureOutput:source audioVoiceNumber:[source getBufferVoice:buffers]] ;
//                }
//            }
//
//        }
        return status;
    }
}

#pragma mark -- CallBack
static OSStatus handleInputBufferAMR(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    @autoreleasepool {
        NSLog(@"du: in handleInputBuffer");

        /* requested mode */
        enum Mode req_mode = MR122;
        const int AMR_BUFFER_SIZE = 32;
        char amrBuffer[AMR_BUFFER_SIZE];
        
        LFAudioCapture *source = (__bridge LFAudioCapture *)inRefCon;
        if (!source) return -1;

        AudioBuffer buffer;
        buffer.mData = NULL;
        buffer.mDataByteSize = 0;
        buffer.mNumberChannels = 1;
        
        AudioBufferList buffers;
        buffers.mNumberBuffers = 1;
        buffers.mBuffers[0] = buffer;
        
        OSStatus status = AudioUnitRender(source.componetInstance,
                                          ioActionFlags,
                                          inTimeStamp,
                                          inBusNumber,
                                          inNumberFrames,
                                          &buffers);

        if (source.muted) {
            double lastSendTime = source.lastSendTime ;
            double currentTime = [[NSDate date] timeIntervalSince1970] ;
            if (currentTime - lastSendTime < 1) {
                return status;
            }
            source.lastSendTime = currentTime;
            NSLog(@"source.muted: %d\n", buffers.mBuffers[0].mDataByteSize);
            for (int i = 0; i < buffers.mNumberBuffers; i++) {
                AudioBuffer ab = buffers.mBuffers[i];
                memset(ab.mData, 0, ab.mDataByteSize);
            }
        }
        if (!status) {
            if (source.delegate && [source.delegate respondsToSelector:@selector(captureOutput:audioData:)]) {
                    int sizeRemain = buffers.mBuffers[0].mDataByteSize/2;
                    short *frame = (short *)buffers.mBuffers[0].mData;
                    int sizeProcessed = 0;
                    int pcmBufferEmptySize = PCM_BUFFER_SIZE - pcmBufferDataSize;
                    while (sizeRemain >= pcmBufferEmptySize) {
                        memcpy((char*)(pcmBuffer + pcmBufferDataSize), (char*)(frame + sizeProcessed), pcmBufferEmptySize * 2);
                        
                        int amrDataSize = Encoder_Interface_Encode(enstate, req_mode, pcmBuffer, amrBuffer, 0);
                        
#if DUMP_AUDIO
                        if(fp_dumpAudio)
                            fwrite(amrBuffer, 1, 32, fp_dumpAudio);
#endif
                        [source.delegate captureOutput:source audioData:[NSData dataWithBytes:amrBuffer
                            length:amrDataSize]];
                        
                        sizeRemain -= pcmBufferEmptySize;
                        sizeProcessed += pcmBufferEmptySize;
                        pcmBufferDataSize = 0;
                        pcmBufferEmptySize = PCM_BUFFER_SIZE - pcmBufferDataSize;
                    }
                    if(sizeRemain > 0) {
                        memcpy((char*)(pcmBuffer + pcmBufferDataSize), (char*)(frame + sizeProcessed), sizeRemain * 2);
                        pcmBufferDataSize += sizeRemain;
                    }
            }

            if (source.delegate && [source.delegate respondsToSelector:@selector(captureOutput:audioVoiceNumber:)] ) {
                [source.delegate captureOutput:source audioVoiceNumber:[source getBufferVoice:buffers]];
            }
        }
        return status;
    }
}


- (NSArray<NSNumber *> *)getBufferVoice:(AudioBufferList) audioBufferList{
    AudioBuffer audioBuffer = audioBufferList.mBuffers[0];
    Byte *frame = (Byte *)audioBuffer.mData;
    int d = audioBuffer.mDataByteSize/2;
    NSMutableArray * bytes = [NSMutableArray new];
    for(long i=0; i<d; i++){
        long x1 = frame[i*2+1]<<8;
        long x2 = frame[i*2];
        short int w = x1 | x2;
        float y = ( w > 16384.f ? 16384.f : w ) / 16384.f ;
        [bytes addObject:[NSNumber numberWithFloat:y]];
    }
    return bytes;
}

-(BOOL)isQuite:(NSData *)pcmData
{
    if (pcmData == nil)
    {
        return NO;
    }
    
    long long pcmAllLenght = 0;
    
    short butterByte[pcmData.length/2];
    memcpy(butterByte, pcmData.bytes, pcmData.length);//frame_size * sizeof(short)
    
    // 将 buffer 内容取出，进行平方和运算
    for (int i = 0; i < pcmData.length/2; i++)
    {
        pcmAllLenght += butterByte[i] * butterByte[i];
    }
    // 平方和除以数据总长度，得到音量大小。
    double mean = pcmAllLenght / (double)pcmData.length;
    double volume =10*log10(mean);//volume为分贝数大小
    
    
    NSLog(@"isQuite ----   %f",volume);
    if (volume >= 45) //45分贝
    {
        
        
    }
    
    return YES;
}

@end

