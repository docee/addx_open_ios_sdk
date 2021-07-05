
#import "RTCMacros.h"
#import <Foundation/Foundation.h>


RTC_OBJC_EXPORT
@interface AddxAudioTestAdapter : NSObject

- (void)setAudioTest: (NSString*)fileDir testOpen: (bool)bTest appVersion:(NSString*)version;

@end