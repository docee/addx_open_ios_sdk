//
//  ADMediaAssetExportSession.h
//  ADDXWebRTC
//
//  Created by addx-wjin on 2021/3/24.
//

#import <Foundation/Foundation.h>
#import "KMMediaAsset.h"

NS_ASSUME_NONNULL_BEGIN

/*
 Export session status
 */

typedef NS_ENUM(NSInteger, KMMediaAssetExportSessionStatus) {
    KMMediaAssetExportSessionStatusUnknown,
    KMMediaAssetExportSessionStatusWaiting,      /* The export session operation is waiting to be executed */
    KMMediaAssetExportSessionStatusExporting,    /* The export session operation is executing */
    KMMediaAssetExportSessionStatusCompleted,    /* The export session operation finished successfully */
    KMMediaAssetExportSessionStatusFailed,       /* The export session operation failed */
    KMMediaAssetExportSessionStatusCanceled,     /* The export session operation is canceled */
};

/*
 Export session error
 */
static NSString *KMMediaAssetExportSessionErrorDomain = @"KMMediaAssetExportSessionErrorDomain";

typedef NS_ENUM(NSUInteger, KMMediaAssetExportSessionErrorCode) {
    KMMediaAssetExportSessionErrorCodeInvalidInput,
    KMMediaAssetExportSessionErrorCodeInvalidOutput,
    KMMediaAssetExportSessionErrorCodeUnsupportedOperation,
    KMMediaAssetExportSessionErrorCodeDemuxOperationFailed,
};

@interface ADMediaAssetExportSession : NSObject

/* The export session’s output assets */
@property (nonatomic, strong) NSArray *outputAssets;

/* Indicates the status of the export session */
@property (nonatomic, readonly) KMMediaAssetExportSessionStatus status;

/*
 Describes the error that occured if:
 - the export status is KMMediaAssetExportSessionStatusFailed
 - the export session is not valid
 
 Error are from KMMediaAssetExportSessionErrorDomain.
 */
@property (nonatomic, readonly) NSError *error;

/**
 Initialize an KMMediaAssetExportSession and set the list of input assets to be exported but the list of assets which are the result of the export session's output have to be set via the outputAssets property
 @param inputAssets An array of KMMediaAsset that are intended to be exported. The order of the assets in the NSArray determine the order in which they are concatenated.
 @return the initialized KMMediaAssetExportSession
 */

- (id)initWithInputAssets:(NSArray *)inputAssets;


/**
 Return if an export session is valid, set the error if not.
 This only evaluate the KMMediaFormat of the input and output KMMediaAsset.
 This method is called at the beginning of the exportAsynchronouslyWithCompletionHandler: selector
 @return true if the export session is among the valid operation, false otherwise
 */

- (BOOL)isAValidExportSession;

/**
 Starts the asynchronous execution of an export session. If the output asset already exists it is overwritten by the export.
 @param handler
 If internal preparation for export fails, the handler will be invoked synchronously.
 The handler may also be called asynchronously after -exportAsynchronouslyWithCompletionHandler: returns,
 in the following cases:
 1) if a failure occurs during the export, including failures of loading, re-encoding, or writing media data to the output,
 2) if export session succeeds, having completely written its output to the outputAssets.
 In each case, KMMediaAssetExportSession.status will signal the terminal state of the asset reader, and if a failure occurs, the NSError that describes the failure can be obtained from the error property.
 */
- (void)exportAsynchronouslyWithCompletionHandler:(void (^)(void))handler;


/*
 TO DO
 */

/* Specifies the progress of the export on a scale from 0 to 1.0.  A value of 0 means the export has not yet begun, A value of 1.0 means the export is complete.
 NOT IMPLEMENTED IN THE FIRST VERSION
 @property (nonatomic, readonly) float progress;
 */

/*
 Cancels the execution of an export session.
- (void)cancelExport;
 */



@end

NS_ASSUME_NONNULL_END
