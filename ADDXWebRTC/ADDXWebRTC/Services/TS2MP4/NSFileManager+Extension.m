//
//  NSFileManager+Extension.m
//  ADDXWebRTC
//
//  Created by addx-wjin on 2021/3/24.
//

#import "NSFileManager+Extension.h"

@implementation NSFileManager (Extension)

-(NSURL *)adCreateUniqueTemporaryDirectory
{
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:guid];
    if([self fileExistsAtPath:path isDirectory:nil])
    {
        NSLog(@"This should not happen since collision rate are low.");
        return nil;
    }
    if (![self createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil])
    {
        NSLog(@"Cannot create the temporary directory.");
        return nil;
    }
    return [NSURL URLWithString:path];
}


@end
