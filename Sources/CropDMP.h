//
//  CropDMP.h
//
//  Copyright © 2019 CROP.network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "CropDMPAPIMode.h"
#import "CropDMPJurisdiction.h"
#import "CropDMPDeviceInfoSource.h"

extern NSString *const CropDMPReceivedBannerURLNotification;
extern NSString *const CropDMPFailedToReceiveBannerURLNotification;

typedef enum {
    CropDMPPrivacyConsentNone,            // Disable CropDMP
    CropDMPPrivacyConsentNonPersonalized, // Don't send any user info
    CropDMPPrivacyConsentPersonalized     // Send user & device info
} CropDMPPrivacyConsent;

@interface CropDMP : NSObject

+ (void)initializeWithAPIKey:(NSString *)key; // Use production API by default
+ (void)initializeWithAPIKey:(NSString *)key apiMode:(CropDMPAPIMode)mode;
+ (instancetype)sharedInstance;

- (void)addDeviceInfoSource:(id<CropDMPDeviceInfoSource>)source;
- (void)sendAllDeviceInfos;

- (void)checkCurrentJurisdiction:(void(^)(CropDMPJurisdiction jurisdiction))completion;

@property (readonly, nonatomic) NSString *userID;
@property (readonly, nonatomic) NSString *bannerURL;
@property (readonly, nonatomic) BOOL hasBannerURL;

@property (assign, nonatomic) CropDMPPrivacyConsent privacyConsent; // Default is None

@property (assign, nonatomic) CGSize preferredAdBannerSizePixels;
@property (assign, nonatomic) BOOL sendAllDeviceInfosUponChange; // NO by default

// Non-positive value disables periodic uploads. Periodic uploads
// are disabled by default.
@property (assign, nonatomic) NSTimeInterval periodicUploadInterval;

@property (assign, nonatomic) BOOL enableExtensiveLogging;

@end
