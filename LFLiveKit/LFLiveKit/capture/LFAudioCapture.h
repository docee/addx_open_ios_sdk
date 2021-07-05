//
//  LFAudioCapture.h
//  LFLiveKit
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "LFLiveAudioConfiguration.h"
#import <AudioToolbox/AudioToolbox.h>
@class AACEncoder;

#pragma mark -- AudioCaptureNotification
/** compoentFialed will post the notification */
extern NSString *_Nullable const LFAudioComponentFailedToCreateNotification;

@class LFAudioCapture;
/** LFAudioCapture callback audioData */
@protocol LFAudioCaptureDelegate <NSObject>
- (void)captureOutput:(nullable LFAudioCapture *)capture audioData:(nullable NSData*)audioData;
- (void)captureOutput:(nullable LFAudioCapture *)capture audioVoiceNumber:(NSArray <NSNumber *> * _Nonnull)voiceNum;
@end


@interface LFAudioCapture : NSObject

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================

/** The delegate of the capture. captureData callback */
@property (nullable, nonatomic, weak) id<LFAudioCaptureDelegate> delegate;

/** The muted control callbackAudioData,muted will memset 0.*/
@property (nonatomic, assign) BOOL muted;

/** The running control start capture or stop capture*/
@property (nonatomic, assign) BOOL running;

@property (nonatomic ,assign) double lastSendTime;
@property (nonatomic ,strong) AACEncoder * aacEncoder;



#pragma mark - Initializer
///=============================================================================
/// @name Initializer
///=============================================================================
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

/**
   The designated initializer. Multiple instances with the same configuration will make the
   capture unstable.
 */
- (nullable instancetype)initWithAudioConfiguration:(nullable LFLiveAudioConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

- (void)updateConfig;
@end
