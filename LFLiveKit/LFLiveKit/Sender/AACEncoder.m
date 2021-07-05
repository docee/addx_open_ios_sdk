//
//  AACEncoder.m
//  EasyCapture
//
//  Created by phylony on 9/11/16.
//  Copyright © 2016 phylony. All rights reserved.
//

#import "AACEncoder.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>


@interface AACEncoder()

@property (nonatomic) AudioConverterRef audioConverter;

@property (nonatomic) uint8_t *aacBuffer;
@property (nonatomic) NSUInteger aacBufferSize;

@property (nonatomic) char *pcmBuffer;
@property (nonatomic) size_t pcmBufferSize;

@end

static const int PCM_BUFFER_SIZE_FOR_AAC = 600000;
static short _pcmBufferAll[PCM_BUFFER_SIZE_FOR_AAC];
static int _pcmBufferSizeAll = 0;

@implementation AACEncoder

- (id) init {
    if (self = [super init]) {
        _encoderQueue = dispatch_queue_create("AAC Encoder Queue", DISPATCH_QUEUE_SERIAL);
        _callbackQueue = dispatch_queue_create("AAC Encoder Callback Queue", DISPATCH_QUEUE_SERIAL);
        
        _audioConverter = NULL;
        
        _pcmBufferSize = 2048;
        _pcmBuffer = malloc(_pcmBufferSize * sizeof(uint8_t));;
        memset(_pcmBuffer, 0, _pcmBufferSize);
        
        _aacBufferSize = 1024;
        _aacBuffer = malloc(_aacBufferSize * sizeof(uint8_t));
        
        memset(_aacBuffer, 0, _aacBufferSize);
        
        self.delegate = nil;
    }
    
    return self;
}

- (void) dealloc {
    AudioConverterDispose(_audioConverter);
    free(_aacBuffer);
    free(_pcmBuffer);
}

#pragma mark - public method

- (void) encode:(AudioBufferList)sampleBuffer Timer:(CMTime)timer comple: (void (^)(NSData * data, CMTime time,NSError* error))compleBlock{

    if (!_audioConverter) {
        [self setupEncoderFromSampleBuffer:sampleBuffer];
    }
    NSError *error = nil;
    int sizeEmpty = PCM_BUFFER_SIZE_FOR_AAC - _pcmBufferSizeAll;
    int pcmSize = sampleBuffer.mBuffers[0].mDataByteSize;
    char *pcmData = (char *)sampleBuffer.mBuffers[0].mData;
    if(pcmSize > sizeEmpty)
        pcmSize = sizeEmpty;
    memcpy(_pcmBufferAll + _pcmBufferSizeAll , pcmData, pcmSize);
    _pcmBufferSizeAll += pcmSize;
    
    //_pcmBuffer = (char *)sampleBuffer.mBuffers[0].mData;
    //_pcmBufferSize = sampleBuffer.mBuffers[0].mDataByteSize;
    memset(_aacBuffer, 0, _aacBufferSize);
    AudioBufferList outAudioBufferList = {0};
    outAudioBufferList.mNumberBuffers = 1;
    outAudioBufferList.mBuffers[0].mNumberChannels = 1;
    outAudioBufferList.mBuffers[0].mDataByteSize = (UInt32)_aacBufferSize;
    outAudioBufferList.mBuffers[0].mData = _aacBuffer;
    AudioStreamPacketDescription *outPacketDescription = NULL;
    UInt32 ioOutputDataPacketSize = 1;
    OSStatus status = AudioConverterFillComplexBuffer(_audioConverter,
                                             inInputDataProc,
                                             (__bridge void *)(self),
                                             &ioOutputDataPacketSize,
                                             &outAudioBufferList,
                                             outPacketDescription);
    NSData *data = nil;
    if (status == 0) {
        NSData *rawAAC = [NSData dataWithBytes:outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];

        data = rawAAC;
        compleBlock(data,timer,error);

    } else {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    }

}

#pragma mark - 设置属性

- (void) setupEncoderFromSampleBuffer:(AudioBufferList)sampleBuffer {
//    AudioStreamBasicDescription inAudioStreamBasicDescription = {0};
//    inAudioStreamBasicDescription.mFormatID = kAudioFormatLinearPCM;
//    inAudioStreamBasicDescription.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
//    inAudioStreamBasicDescription.mChannelsPerFrame = 1;
//    inAudioStreamBasicDescription.mFramesPerPacket = 1;
//    inAudioStreamBasicDescription.mBitsPerChannel = 16;
//    inAudioStreamBasicDescription.mBytesPerFrame = inAudioStreamBasicDescription.mBitsPerChannel / 8 * inAudioStreamBasicDescription.mChannelsPerFrame;
//    inAudioStreamBasicDescription.mBytesPerPacket = inAudioStreamBasicDescription.mBytesPerFrame * inAudioStreamBasicDescription.mFramesPerPacket;
//
//    inAudioStreamBasicDescription.mSampleRate = 44100;
//
//    
//    AudioStreamBasicDescription outAudioStreamBasicDescription = {0}; // Always initialize the fields of a new audio stream basic description structure to zero, as shown here: ...
//    outAudioStreamBasicDescription.mSampleRate = self.configuration.audioSampleRate; // The number of frames per second of the data in the stream, when the stream is played at normal speed. For compressed formats, this field indicates the number of frames per second of equivalent decompressed data. The mSampleRate field must be nonzero, except when this structure is used in a listing of supported formats (see “kAudioStreamAnyRate”).
//    outAudioStreamBasicDescription.mFormatID = kAudioFormatMPEG4AAC; // kAudioFormatMPEG4AAC_HE does not work. Can't find `AudioClassDescription`. `mFormatFlags` is set to 0.
//    outAudioStreamBasicDescription.mFramesPerPacket = 1024; // The number of frames in a packet of audio
//    outAudioStreamBasicDescription.mChannelsPerFrame = 1;
//    
//    const OSType subtype = kAudioFormatMPEG4AAC;
//    AudioClassDescription requestedCodecs[2] = {
//        {
//            kAudioEncoderComponentType,
//            subtype,
//            kAppleSoftwareAudioCodecManufacturer
//        },
//        {
//            kAudioEncoderComponentType,
//            subtype,
//            kAppleHardwareAudioCodecManufacturer
//        }
//    };
    /*AudioClassDescription *description = [self getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC
//                                                               fromManufacturer:kAppleSoftwareAudioCodecManufacturer];*/
//    OSStatus status = AudioConverterNewSpecific(&inAudioStreamBasicDescription,
//                                                &outAudioStreamBasicDescription,
//                                                2,
//                                                requestedCodecs,
//                                                &_audioConverter);
//    if (status != 0) {
//        NSLog(@"setup converter: %d", (int)status);
//    }
    
//    UInt32 bitRate = 64000;
//    UInt32 uiSize = sizeof(bitRate);
//    status = AudioConverterSetProperty(_audioConverter, kAudioConverterEncodeBitRate, uiSize, &bitRate);
//    
//    UInt32 value = 0;
//    uiSize = sizeof(value);
//    AudioConverterGetProperty(_audioConverter, kAudioConverterPropertyMaximumOutputPacketSize, &uiSize, &value);
//    NSLog(@"packet size = %d", value);
}

- (AudioClassDescription *)getAudioClassDescriptionWithType:(UInt32)type fromManufacturer:(UInt32)manufacturer {
    static AudioClassDescription desc;
    
    UInt32 encoderSpecifier = type;
    OSStatus st;
    
    UInt32 size;
    st = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders,
                                    sizeof(encoderSpecifier),
                                    &encoderSpecifier,
                                    &size);
    if (st) {
        NSLog(@"error getting audio format propery info: %d", (int)(st));
        return nil;
    }
    
    unsigned int count = size / sizeof(AudioClassDescription);
    AudioClassDescription descriptions[count];
    st = AudioFormatGetProperty(kAudioFormatProperty_Encoders,
                                sizeof(encoderSpecifier),
                                &encoderSpecifier,
                                &size,
                                descriptions);
    if (st) {
        NSLog(@"error getting audio format propery: %d", (int)(st));
        return nil;
    }
    
    for (unsigned int i = 0; i < count; i++) {
        if ((type == descriptions[i].mSubType) &&
            (manufacturer == descriptions[i].mManufacturer)) {
            memcpy(&desc, &(descriptions[i]), sizeof(desc));
            return &desc;
        }
    }
    
    return nil;
}

#pragma mark - 回调

static OSStatus inInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) {
    AACEncoder *encoder = (__bridge AACEncoder *)(inUserData);
    UInt32 requestedPackets = *ioNumberDataPackets;
//    NSLog(@"Number of packets requested: %d", (unsigned int)requestedPackets);
    size_t copiedSize = [encoder copyPCMBuffer:ioData];
    if (copiedSize < requestedPackets * 2) {
        //NSLog(@"PCM buffer isn't full enough!");
        *ioNumberDataPackets = 0;
        return -1;
    }
    *ioNumberDataPackets = requestedPackets;
    
    NSLog(@"Copied %zu samples into ioData", copiedSize);
    return noErr;
}

- (size_t) copyPCMBuffer:(AudioBufferList*)ioData {
    size_t originalBufferSize = _pcmBufferSize;
    if(_pcmBufferSizeAll >= _pcmBufferSize){
        memcpy(_pcmBuffer, _pcmBufferAll, _pcmBufferSize);
        _pcmBufferSizeAll -= _pcmBufferSize;
        memcpy(_pcmBufferAll, _pcmBufferAll + _pcmBufferSize, _pcmBufferSizeAll);
    }
    else{
        return 0;
    }
        
    if (!originalBufferSize) {
        return 0;
    }
    ioData->mBuffers[0].mData = _pcmBuffer;
    ioData->mBuffers[0].mDataByteSize = (UInt32)_pcmBufferSize;
//    NSLog(@"Sending %d bytes", _pcmBufferSize);
    //_pcmBuffer = NULL;
    //_pcmBufferSize = 0;
    return originalBufferSize;
}

@end
