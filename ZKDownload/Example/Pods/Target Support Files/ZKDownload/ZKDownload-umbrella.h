#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "FKConfigure.h"
#import "FKDefine.h"
#import "FKDownloader.h"
#import "FKDownloadExecutor.h"
#import "FKDownloadManager.h"
#import "FKHashHelper.h"
#import "FKMapHub.h"
#import "FKReachability.h"
#import "FKResumeHelper.h"
#import "FKSystemHelper.h"
#import "FKTask.h"
#import "FKTaskStorage.h"
#import "NSArray+FKDownload.h"
#import "NSData+FKDownload.h"
#import "NSMutableSet+FKDownload.h"
#import "NSString+FKDownload.h"

FOUNDATION_EXPORT double ZKDownloadVersionNumber;
FOUNDATION_EXPORT const unsigned char ZKDownloadVersionString[];

