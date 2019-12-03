//
//  CropDMPCore.h
//
//  Copyright © 2019 CROP.network. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CropDMPAPIMode.h"
#import "CropDMPJurisdiction.h"

@protocol CropDMPCoreDelegate;

@interface CropDMPCore : NSObject

+ (void)initializeWithAPIKey:(NSString *)key; // Use production API by default
+ (void)initializeWithAPIKey:(NSString *)key apiMode:(CropDMPAPIMode)mode;
+ (instancetype)sharedInstance;

- (void)checkCurrentJurisdiction:(void(^)(CropDMPJurisdiction jurisdiction))completion;

- (void)sendEmptyDictionary;
- (void)sendDictionary:(NSDictionary *)dictionary;

@property (readonly, nonatomic) NSString *apiKey;
@property (readonly, nonatomic) NSString *userID;
@property (readonly, nonatomic) NSString *bannerURL;
@property (readonly, nonatomic) BOOL hasBannerURL;
@property (assign, nonatomic) BOOL enableExtensiveLogging;

@property (weak, nonatomic) id<CropDMPCoreDelegate> delegate;

@end // @interface CropDMPCore

@protocol CropDMPCoreDelegate <NSObject>
@optional - (void)cropDMPCore:(CropDMPCore *)core
            receivedBannerURL:(NSString *)url;
@optional - (void)cropDMPCoreFailedToReceiveBannerURL:(CropDMPCore *)core;
@end // @protocol CropDMPCoreDelegate
