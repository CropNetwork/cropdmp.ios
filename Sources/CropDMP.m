//
//  CropDMP.m
//
//  Copyright © 2019 CROP.network. All rights reserved.
//

#import "CropDMP.h"
#import "CropDMPCore.h"
#import "CropDMPDeviceInfo.h"
#import "CropDMPPayload.h"
#import "CropDMPUtils.h"

static CropDMP *globalInstance = nil;

NSString *const CropDMPReceivedBannerURLNotification = @"CropDMPReceivedBannerURLNotification";
NSString *const CropDMPFailedToReceiveBannerURLNotification = @"CropDMPFailedToReceiveBannerURLNotification";

@interface CropDMP () <CropDMPDeviceInfoSourceDelegate, CropDMPCoreDelegate>

@property (strong, nonatomic) CropDMPCore *core;
@property (strong, nonatomic) NSMutableArray *deviceInfoSources;

@property (strong, nonatomic) CropDMPPayload *payload;

@property (strong, nonatomic) NSTimer *periodicUploadTimer;

@end

@implementation CropDMP

@dynamic userID;
@dynamic bannerURL;
@dynamic hasBannerURL;
@dynamic enableExtensiveLogging;

+ (void)initializeWithAPIKey:(NSString *)key
{
    [self initializeWithAPIKey:key apiMode:CropDMPAPIModeProduction];
}

+ (void)initializeWithAPIKey:(NSString *)key apiMode:(CropDMPAPIMode)mode
{
    CropDMPAssert(globalInstance == nil, @"CropDMP double initialization: -[CropDMPCore initializeWithAPIKey:apiMode:] called more than once");

    [CropDMPCore initializeWithAPIKey:key apiMode:mode];
    globalInstance = [[self alloc] initWithCropDMPCore:[CropDMPCore sharedInstance]];
}

+ (instancetype)sharedInstance
{
    CropDMPAssert(globalInstance != nil, @"Trying to access CropDMP instance without calling -[CropDMPCore initializeWithAPIKey:apiMode:] beforehand");

    return globalInstance;
}

- (instancetype)initWithCropDMPCore:(CropDMPCore *)core
{
    if (!(self = [super init]))
        return nil;

    self.core = core;
    self.deviceInfoSources = [NSMutableArray arrayWithCapacity:5];
    self.payload = [[CropDMPPayload alloc] init];
    self.privacyConsent = CropDMPPrivacyConsentNone;
    self.sendAllDeviceInfosUponChange = NO;

    core.delegate = self;

    return self;
}

- (void)dealloc
{
    if (_periodicUploadTimer) {
        [_periodicUploadTimer invalidate];
        _periodicUploadTimer = nil;
    }
}

- (void)addDeviceInfoSource:(id<CropDMPDeviceInfoSource>)source
{
    if ([_deviceInfoSources indexOfObjectIdenticalTo:source] != NSNotFound) {
        NSLog(@"CropDMP: Warning: Attempt to add the same device info source twice");
        return;
    }

    source.delegate = self;
    [_deviceInfoSources addObject:source];
}

- (void)sendAllDeviceInfos
{
    if (_privacyConsent == CropDMPPrivacyConsentNone)
        return;

    if (_privacyConsent == CropDMPPrivacyConsentPersonalized) {
        NSMutableArray *allDeviceInfoDicts = [[NSMutableArray alloc] init];

        for (id<CropDMPDeviceInfoSource> source in _deviceInfoSources) {
            for (CropDMPDeviceInfo *deviceInfo in source.deviceInfos) {
                [allDeviceInfoDicts addObject:[deviceInfo toDictionary]];
            }
        }
        _payload.commonData.deviceInfos = allDeviceInfoDicts;
    }

    _payload.adsOptionsData.width = @(_preferredAdBannerSizePixels.width);
    _payload.adsOptionsData.height = @(_preferredAdBannerSizePixels.height);
    [_core sendDictionary:[_payload toDictionary]];
}

- (void)checkCurrentJurisdiction:(void(^)(CropDMPJurisdiction jurisdiction))completion
{
    [_core checkCurrentJurisdiction:completion];
}

- (NSString *)userID
{
    return _core.userID;
}

- (NSString *)bannerURL
{
    return _core.bannerURL;
}

- (BOOL)hasBannerURL
{
    return _core.hasBannerURL;
}

- (void)setPrivacyConsent:(CropDMPPrivacyConsent)privacyConsent
{
    if (_privacyConsent == privacyConsent)
        return;

    _privacyConsent = privacyConsent;

    if (_sendAllDeviceInfosUponChange)
        [self sendAllDeviceInfos];
}

- (void)cropDMPDeviceInfoSource:(id<CropDMPDeviceInfoSource>)source
             deviceInfosChanged:(NSArray *)deviceInfo
{
    if (_sendAllDeviceInfosUponChange) {
        [self sendAllDeviceInfos];
    }
}

- (void)setPeriodicUploadInterval:(NSTimeInterval)periodicUploadInterval
{
    if (_periodicUploadInterval == periodicUploadInterval)
        return;

    _periodicUploadInterval = periodicUploadInterval;

    if (_periodicUploadTimer) {
        [_periodicUploadTimer invalidate];
        _periodicUploadTimer = nil;
    }

    if (_periodicUploadInterval > 0) {
        _periodicUploadTimer = [NSTimer scheduledTimerWithTimeInterval:_periodicUploadInterval target:self selector:@selector(sendAllDeviceInfos) userInfo:nil repeats:YES];
    }
}

- (BOOL)enableExtensiveLogging
{
    return _core.enableExtensiveLogging;
}

- (void)setEnableExtensiveLogging:(BOOL)enableExtensiveLogging
{
    _core.enableExtensiveLogging = enableExtensiveLogging;
}

- (void)cropDMPCore:(CropDMPCore *)core receivedBannerURL:(NSString *)url
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CropDMPReceivedBannerURLNotification object:self];
}

- (void)cropDMPCoreFailedToReceiveBannerURL:(CropDMPCore *)core
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CropDMPFailedToReceiveBannerURLNotification object:self];
}

@end
