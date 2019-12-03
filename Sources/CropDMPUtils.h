//
//  CropDMPUtils.h
//
//  Copyright © 2019 CROP.network. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef NDEBUG
#define CropDMPLogAssertionFailure(...) [[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSUTF8StringEncoding] file:[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lineNumber:__LINE__ description:__VA_ARGS__]
#else
#define CropDMPLogAssertionFailure(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#endif

#define CropDMPAssert(condition, ...) do {   \
if (!(condition)) {                          \
    CropDMPLogAssertionFailure(__VA_ARGS__); \
}                                            \
} while (0)

#define CropDMPTestLog(instance, ...) do {     \
if (instance.enableExtensiveLogging)    \
    NSLog(__VA_ARGS__);                        \
} while (0)

@interface CropDMPUtils : NSObject

+ (NSString *)md5FromData:(NSData *)data;
+ (NSString *)sha256FromData:(NSData *)data;
+ (NSString *)hashPersonalString:(NSString *)personalString;

@end
