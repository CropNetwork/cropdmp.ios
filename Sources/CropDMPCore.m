//
//  CropDMPCore.m
//
//  Copyright © 2019 CROP.network. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CropDMPCore.h"
#import "CropDMPUtils.h"

static NSString *cropDMPProductionURL = @"https://api.crop.network/v1/rest/app";
static NSString *cropDMPTestURL = @"https://api.crop.network/v1/rest/app/test";

static NSString *cropDMPOnloadNumberKey = @"network.crop.onloadNumber";
static NSString *cropDMPServerProvidedIdKey = @"network.crop.serverProvidedId";
static NSString *cropDMPIFrameURLKey = @"network.crop.iFrameUrl";
static NSString *cropDMPPendingDataJsonKey = @"network.crop.pendingDataJson";

static CropDMPCore *globalInstance = nil;

// Doesn't change success flag if error didn't occur.
static NSString *parseStringOrNull(NSDictionary *dictionary, NSString *key, BOOL *success);
static NSNumber *parseNumberOrNull(NSDictionary *dictionary, NSString *key, BOOL *success);
static NSDictionary *parseDictOrNull(NSDictionary *dictionary, NSString *key, BOOL *success);

@interface CropDMPResponse : NSObject

+ (instancetype)fromJson:(id)json;

@property (readonly, nonatomic) BOOL statusOK;
@property (readonly, nonatomic) NSString *serverProvidedID;
@property (readonly, nonatomic) NSString *iFrameURL;

@end // @interface CropDMPResponse

@interface CropDMPGeoIPResponse : NSObject

+ (instancetype)fromJson:(id)json;

@property (readonly, nonatomic) BOOL statusOK;
@property (readonly, nonatomic) NSString *countryISOCode;
@property (readonly, nonatomic) NSNumber *isEUCountry; // BOOL

@end // @interface CropDMPGeoIPResponse

@interface CropDMPCore ()

@property (copy, nonatomic) NSString *apiKey;
@property (assign, nonatomic) CropDMPAPIMode apiMode;
@property (strong, readonly, nonatomic) NSURLSession *urlSession;

@property (copy, nonatomic) NSString *appLaunchId;
@property (copy, nonatomic) NSString *sessionUniqueId;
@property (assign, nonatomic) int onloadNumber;
@property (copy, nonatomic) NSString *lastSentDataMd5;

@end // @interface CropDMPCore ()

@implementation CropDMPCore

@dynamic userID;
@dynamic bannerURL;
@dynamic hasBannerURL;

+ (void)initializeWithAPIKey:(NSString *)key
{
    [self initializeWithAPIKey:key apiMode:CropDMPAPIModeProduction];
}

+ (void)initializeWithAPIKey:(NSString *)key apiMode:(CropDMPAPIMode)mode
{
    CropDMPAssert(globalInstance == nil, @"CropDMPCore double initialization: -[CropDMPCore initializeWithAPIKey:apiMode:] called more than once");

    globalInstance = [[self alloc] initWithAPIKey:key apiMode:mode];
}

+ (instancetype)sharedInstance
{
    CropDMPAssert(globalInstance != nil, @"Trying to access CropDMPCore instance without calling -[CropDMPCore initializeWithAPIKey:apiMode:] beforehand");

    return globalInstance;
}

- (instancetype)initWithAPIKey:(NSString *)key apiMode:(CropDMPAPIMode)mode
{
    if (!(self = [super init]))
        return nil;

    self.apiKey = key;
    self.apiMode = mode;

    const int64_t msecsSinceEpoch = (int64_t)(([NSDate timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970) * 1000);

    self.appLaunchId = [NSString stringWithFormat:@"%d", arc4random()];
    self.sessionUniqueId = [NSString stringWithFormat:@"%@%lld", _appLaunchId, msecsSinceEpoch];

    self.onloadNumber = 1 + [self intValueForKey:cropDMPOnloadNumberKey defaultValue:0];
    [self saveIntValue:_onloadNumber forKey:cropDMPOnloadNumberKey];

    self.enableExtensiveLogging = mode == CropDMPAPIModeTest;

    CropDMPTestLog(self, @"CropDMPCore: Initialized with API key %@ onload number %d", _apiKey, _onloadNumber);

    return self;
}

- (void)checkCurrentJurisdiction:(void(^)(CropDMPJurisdiction jurisdiction))completion
{
    NSMutableString *urlString = [NSMutableString stringWithString:[self apiBaseURL]];
    [urlString appendString:@"/geo"];
    [urlString appendFormat:@"?key=%@", [self percentEncodeURLParameter:_apiKey]];

    NSURL *url = [NSURL URLWithString:urlString];

    CropDMPAssert(url != nil, @"CropDMPCore failed to construct URL");

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";

    CropDMPCore *__weak weakSelf = self;
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!weakSelf)
                return;

            void (^callCompletion)(CropDMPJurisdiction jurisdiction) = ^(CropDMPJurisdiction jurisdiction) {
                if (completion)
                    completion(jurisdiction);
            };

            if (error) {
                NSLog(@"CropDMPCore: Failed to perform GeoIP request: %@", error.localizedDescription);

                callCompletion(CropDMPJurisdictionUnknown);
                return;
            }

            NSError *__autoreleasing parseError = nil;
            id responseJsonRoot = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&parseError];
            if (parseError) {
                NSLog(@"CropDMPCore: Failed to parse GeoIP response JSON: %@. Data: %@", parseError.localizedDescription, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

                callCompletion(CropDMPJurisdictionUnknown);
                return;
            }

            CropDMPGeoIPResponse *parsedResponse = [CropDMPGeoIPResponse fromJson:responseJsonRoot];
            if (!parsedResponse) {
                NSLog(@"CropDMPCore: Received invalid GeoIP response. Data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

                callCompletion(CropDMPJurisdictionUnknown);
                return;
            }

            NSLog(@"CropDMPCore: Received geolocation: %@", parsedResponse.countryISOCode);

            if (parsedResponse.isEUCountry != nil) {
                BOOL isEU = [parsedResponse.isEUCountry boolValue];
                callCompletion(isEU ? CropDMPJurisdictionEU : CropDMPJurisdictionNotEU);
            } else {
                callCompletion(CropDMPJurisdictionUnknown);
            }
        });
    }];

    [dataTask resume];
}

- (void)sendEmptyDictionary
{
    [self sendDictionary:[[NSDictionary alloc] init]];
}

- (void)sendDictionary:(NSDictionary *)json
{
    json = [self prepareDataDictionary:json];

    NSArray *jsonArray = [self arrayByAppendingPendingDataToDictionary:json];
    [self removeValueForKey:cropDMPPendingDataJsonKey];

    NSError *serializationError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonArray
                                                       options:kNilOptions
                                                         error:&serializationError];

    if (jsonData == nil) {
        NSLog(@"CropDMPCore: JSON serialization error: %@", serializationError.localizedDescription);
        jsonData = [@"[]" dataUsingEncoding:NSUTF8StringEncoding];
    }

    [self sendJSONData:jsonData];
}

- (NSString *)userID
{
    NSLog(@"USER ID: %@", [self stringValueForKey:cropDMPServerProvidedIdKey
                                     defaultValue:nil]);
    return [self stringValueForKey:cropDMPServerProvidedIdKey
                      defaultValue:nil];
}

- (NSString *)bannerURL
{
    return [self stringValueForKey:cropDMPIFrameURLKey defaultValue:nil];
}

- (BOOL)hasBannerURL
{
    NSString *bannerURL = self.bannerURL;
    return bannerURL && bannerURL.length > 0;
}

- (void)sendJSONString:(NSString *)json
{
    [self sendJSONData:[json dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)sendJSONData:(NSData *)jsonData
{
    NSString *jsonDataHash = [CropDMPUtils md5FromData:jsonData];
    if (self.lastSentDataMd5 && [jsonDataHash isEqualToString:self.lastSentDataMd5]) {
        CropDMPTestLog(self, @"CropDMPCore: Not sending data with the same hash");
        return;
    }

    CropDMPTestLog(self, @"CropDMPCore: Sending data with md5 %@ content: %@", jsonDataHash, [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);

    NSURLRequest *request = [self constructAPIRequestWithPayload:jsonData];

    CropDMPCore *__weak weakSelf = self;
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!weakSelf)
                return;

            if (error) {
                NSLog(@"CropDMPCore: Failed to perform HTTP request: %@", error.localizedDescription);

                [weakSelf notifyFailedToReceiveBannerURL];
                [weakSelf saveDataValue:jsonData forKey:cropDMPPendingDataJsonKey];
                return;
            }

            NSError *__autoreleasing parseError = nil;
            id responseJsonRoot = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&parseError];
            if (parseError) {
                NSLog(@"CropDMPCore: Failed to parse response JSON: %@. Data: %@", parseError.localizedDescription, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

                [weakSelf notifyFailedToReceiveBannerURL];
                [weakSelf saveDataValue:jsonData forKey:cropDMPPendingDataJsonKey];
                return;
            }

            CropDMPResponse *parsedResponse = [CropDMPResponse fromJson:responseJsonRoot];
            if (!parsedResponse) {
                NSLog(@"CropDMPCore: Received invalid response. Data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

                [weakSelf notifyFailedToReceiveBannerURL];
                [weakSelf saveDataValue:jsonData forKey:cropDMPPendingDataJsonKey];
                return;
            }

            CropDMPTestLog(weakSelf, @"CropDMPCore: Received response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

            if (parsedResponse.serverProvidedID) {
                [weakSelf saveStringValue:parsedResponse.serverProvidedID
                                   forKey:cropDMPServerProvidedIdKey];
            } else {
                [weakSelf removeValueForKey:cropDMPServerProvidedIdKey];
            }

            NSString *iFrameURL = parsedResponse.iFrameURL;
            if (iFrameURL && iFrameURL.length > 0) {
                [weakSelf notifyBannerURLReceived:iFrameURL];
                [weakSelf saveStringValue:iFrameURL
                                   forKey:cropDMPIFrameURLKey];
            } else {
                [weakSelf notifyFailedToReceiveBannerURL];
            }

            if (parsedResponse.statusOK) {
                weakSelf.lastSentDataMd5 = jsonDataHash;
            } else {
                CropDMPTestLog(weakSelf, @"CropDMPCore: Server refused to accept the data");
            }
        });
    }];

    [dataTask resume];
}

- (NSArray *)arrayByAppendingPendingDataToDictionary:(NSDictionary *)dictionary
{
    NSData *pendingJsonData = [self dataValueForKey:cropDMPPendingDataJsonKey defaultValue:nil];
    if (!pendingJsonData) {
        return @[dictionary];
    }

    NSError *__autoreleasing parseError = nil;
    id pendingJsonRoot = [NSJSONSerialization JSONObjectWithData:pendingJsonData
                                                          options:NSJSONReadingMutableContainers
                                                            error:&parseError];
    if (parseError) {
        CropDMPAssert(NO, @"CropDMPCore: Failed to parse saved pending JSON: %@", parseError.localizedDescription);
        return @[dictionary];
    }

    if (![pendingJsonRoot isKindOfClass:[NSMutableArray class]]) {
        CropDMPAssert(NO, @"CropDMPCore: Saved pending JSON is not an array");
        return @[dictionary];
    }

    NSMutableArray *pendingJsonArray = pendingJsonRoot;
    [pendingJsonArray insertObject:dictionary atIndex:0];

    return pendingJsonArray;
}

- (NSDictionary *)prepareDataDictionary:(NSDictionary *)dictionary
{
    id personalValue = dictionary[@"personal"];
    if (!personalValue || ![personalValue isKindOfClass:[NSDictionary class]])
        return dictionary;

    NSMutableDictionary *preparedDictionary = [dictionary mutableCopy];
    preparedDictionary[@"personal"] = [self preparePersonalDataDictionary:personalValue];

    return preparedDictionary;
}

- (NSDictionary *)preparePersonalDataDictionary:(NSDictionary *)dictionary
{
    NSMutableDictionary *preparedDictionary = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];

    for (NSString *key in dictionary) {
        NSString *value = dictionary[key];

        if ([self isPhoneNumberKey:key]) {
            value = [self removeNonDigitsFromPhoneNumber:value];
        } else {
            value = [value lowercaseString];
        }

        preparedDictionary[key] = [CropDMPUtils hashPersonalString:value];
    }

    return preparedDictionary;
}

- (BOOL)isPhoneNumberKey:(NSString *)key
{
    NSArray *phonePossibleKeys = @[ @"phone", @"phoneNumber", @"telephone", @"tel", @"telNumber", @"telephoneNumber", @"mobile", @"mobileNumber" ];
    NSUInteger foundIndex = [phonePossibleKeys indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj caseInsensitiveCompare:key] == NSOrderedSame;
    }];

    return foundIndex != NSNotFound;
}

- (NSString *)removeNonDigitsFromPhoneNumber:(NSString *)phoneNumber
{
    return [[phoneNumber componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet].invertedSet] componentsJoinedByString:@""];
}

#pragma mark -

- (NSString *)percentEncodeURLParameter:(NSString *)value
{
    return [value stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
}

- (NSString *)apiBaseURL
{
    switch (_apiMode) {
        case CropDMPAPIModeProduction:
            return cropDMPProductionURL;
        case CropDMPAPIModeTest:
            return cropDMPTestURL;
        default:
            CropDMPAssert(false, @"Unknown API mode: %d", (int)_apiMode);
            break;
    }

    return cropDMPTestURL;
}

- (NSURLRequest *)constructAPIRequestWithPayload:(NSData *)payload
{
    NSMutableString *urlString = [NSMutableString stringWithString:[self apiBaseURL]];
    NSString *uniqueID = [self stringValueForKey:cropDMPServerProvidedIdKey
                                    defaultValue:@""];

    [urlString appendFormat:@"?key=%@&session=%@&id=%@&onnumber=%d&platform=ios",
     [self percentEncodeURLParameter:_apiKey],
     [self percentEncodeURLParameter:_sessionUniqueId],
     [self percentEncodeURLParameter:uniqueID],
     _onloadNumber];

    NSURL *url = [NSURL URLWithString:urlString];

    CropDMPAssert(url != nil, @"CropDMPCore failed to construct URL");

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";
    request.HTTPBody = payload;

    return request;
}

- (NSURLSession *)urlSession
{
    return [NSURLSession sharedSession];
}

#pragma mark -

- (NSString *)stringValueForKey:(NSString *)key defaultValue:(NSString *)defaultValue
{
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    return value ? value : defaultValue;
}

- (void)saveStringValue:(NSString *)value forKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
}

- (int)intValueForKey:(NSString *)key defaultValue:(int)defaultValue
{
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    return number ? [number intValue] : defaultValue;
}

- (void)saveIntValue:(int)value forKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:value] forKey:key];
}

- (NSData *)dataValueForKey:(NSString *)key defaultValue:(NSData *)defaultValue
{
    NSData *value = [[NSUserDefaults standardUserDefaults] dataForKey:key];
    return value ? value : defaultValue;
}

- (void)saveDataValue:(NSData *)value forKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
}

- (void)removeValueForKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
}

#pragma mark -

- (void)notifyBannerURLReceived:(NSString *)url
{
    if ([_delegate respondsToSelector:@selector(cropDMPCore:receivedBannerURL:)])
    {
        [_delegate cropDMPCore:self receivedBannerURL:url];
    }
}

- (void)notifyFailedToReceiveBannerURL
{
    if ([_delegate respondsToSelector:@selector(cropDMPCoreFailedToReceiveBannerURL:)])
    {
        [_delegate cropDMPCoreFailedToReceiveBannerURL:self];
    }
}

@end // @implementation CropDMPCore

#pragma mark -

@implementation CropDMPResponse

+ (instancetype)fromJson:(id)json
{
    if (![json isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"CropDMPCore: Incorrect response: JSON root is not an object");
        return nil;
    }

    NSDictionary *jsonObject = (NSDictionary *)json;

    BOOL success = YES;
    NSString *status = parseStringOrNull(jsonObject, @"status", &success);
    NSString *idString = parseStringOrNull(jsonObject, @"id", &success);
    NSString *iFrameURL = parseStringOrNull(jsonObject, @"ifrSrc", &success);

    if (!status) {
        NSLog(@"CropDMPCore: Invalid response: status is null");
        return nil;
    }

    CropDMPResponse *response = [[CropDMPResponse alloc] init];
    response->_statusOK = [status isEqualToString:@"ok"];
    response->_serverProvidedID = [idString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    response->_iFrameURL = iFrameURL;

    return response;
}

@end // @implementation CropDMPResponse

@implementation CropDMPGeoIPResponse

+ (instancetype)fromJson:(id)json
{
    if (![json isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"CropDMPCore: Incorrect GeoIP response: JSON root is not an object");
        return nil;
    }

    NSDictionary *jsonObject = (NSDictionary *)json;

    BOOL success = YES;
    NSString *status = parseStringOrNull(jsonObject, @"status", &success);
    NSString *isoCountryCode = nil;
    NSNumber *isEUCountry = nil;
    NSDictionary *geoData = parseDictOrNull(jsonObject, @"geo", &success);
    if (geoData) {
        NSDictionary *country = parseDictOrNull(geoData, @"country", &success);
        if (country) {
            isoCountryCode = parseStringOrNull(country, @"iso", &success);
            isEUCountry = parseNumberOrNull(country, @"eu", &success);
        }
    }

    if (!status) {
        NSLog(@"CropDMPCore: Invalid GeoIP response: status is null");
        return nil;
    }

    CropDMPGeoIPResponse *response = [[CropDMPGeoIPResponse alloc] init];
    response->_statusOK = [status isEqualToString:@"ok"];
    response->_countryISOCode = isoCountryCode;
    response->_isEUCountry = isEUCountry;

    return response;
}

@end

id parseIdOrNull(NSDictionary *dictionary, NSString *key, BOOL *success)
{
    id value = [dictionary valueForKey:key];
    if (!value) {
        NSLog(@"CropDMPCore: Invalid response: Field \"%@\" doesn't exist", key);
        if (success)
            *success = NO;
        return nil;
    }

    if (value == [NSNull null])
        return nil;

    return value;
}

NSString *parseStringOrNull(NSDictionary *dictionary, NSString *key, BOOL *success)
{
    BOOL successLocal = YES;

    id value = parseIdOrNull(dictionary, key, &successLocal);
    if (!successLocal) {
        if (success)
            *success = NO;
        return nil;
    }

    if ([value isKindOfClass:[NSString class]])
        return (NSString *)value;

    NSLog(@"CropDMPCore: Invalid response: Field \"%@\" is neither string nor null", key);
    if (success)
        *success = NO;

    return nil;
}

static NSNumber *parseNumberOrNull(NSDictionary *dictionary, NSString *key, BOOL *success)
{
    BOOL successLocal = YES;

    id value = parseIdOrNull(dictionary, key, &successLocal);
    if (!successLocal) {
        if (success)
            *success = NO;
        return nil;
    }

    if ([value isKindOfClass:[NSNumber class]])
        return (NSNumber *)value;

    NSLog(@"CropDMPCore: Invalid response: Field \"%@\" is neither NSValue nor null", key);

    if (success)
        *success = NO;

    return nil;
}

NSDictionary *parseDictOrNull(NSDictionary *dictionary, NSString *key, BOOL *success)
{
    BOOL successLocal = YES;

    id value = parseIdOrNull(dictionary, key, &successLocal);
    if (!successLocal) {
        if (success)
            *success = NO;
        return nil;
    }

    if ([value isKindOfClass:[NSDictionary class]])
        return (NSDictionary *)value;

    NSLog(@"CropDMPCore: Invalid response: Field \"%@\" is neither object nor null", key);

    if (success)
        *success = NO;

    return nil;
}
