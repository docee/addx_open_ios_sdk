//
//  NSFileManager+Extension.h
//  ADDXWebRTC
//
//  Created by addx-wjin on 2021/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (Extension)

-(NSURL *)adCreateUniqueTemporaryDirectory;

@end

NS_ASSUME_NONNULL_END
