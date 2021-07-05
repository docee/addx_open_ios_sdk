//
//  AACEncoder.h
//  EasyCapture
//
//  Created by phylony on 9/11/16.
//  Copyright © 2016 phylony. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "aacenc_lib.h"

@protocol AACEncoderDelegate <NSObject>

@required
- (void)gotAACEncodedData:(NSData *)data timestamp:(CMTime)timestamp error:(NSError*)error;

@end

@interface AACEncoder : NSObject

@property (weak, nonatomic) id<AACEncoderDelegate> delegate;

@property (nonatomic) dispatch_queue_t encoderQueue;
@property (nonatomic) dispatch_queue_t callbackQueue;

- (void) encode:(AudioBufferList)sampleBuffer Timer:(CMTime)timer comple:(void (^)(NSData * data, CMTime time,NSError* error)) compleBlock ;

@end
