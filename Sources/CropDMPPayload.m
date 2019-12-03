//
//  CropDMPPayload.m
//
//  Copyright © 2019 CROP.network. All rights reserved.
//

#import "CropDMPPayload.h"
#import "CropDMPUtils.h"

@implementation CropDMPPayload

- (instancetype)init
{
    if (!(self = [super init]))
        return nil;

    _commonData = [[CropDMPPayloadCommonData alloc] init];
    _hashData = [[CropDMPPayloadHashData alloc] init];
    _adsOptionsData = [[CropDMPPayloadAdsOptionsData alloc] init];

    return self;
}

- (NSDictionary *)toDictionary
{
    return @{ @"data": [_commonData toDictionary],
              @"hashData": [_hashData toDictionary],
              @"adsOptions": [_adsOptionsData toDictionary]
    };
}

@end // @implementation CropDMPPayload

@implementation CropDMPPayloadCommonData

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if (_deviceInfos)
        dict[@"devices"] = _deviceInfos;
    if (_cellEmei)
        dict[@"cellEmei"] = _cellEmei;

    return dict;
}

@end // @implementation CropDMPPayloadCommonData

@implementation CropDMPPayloadHashData

- (NSDictionary *)toDictionary
{
    return @{};
}

@end // @implementation CropDMPPayloadHashData

static NSString *adTypeToString(CropDMPAdType type);
@implementation CropDMPPayloadAdsOptionsData

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"type"] = _type ? adTypeToString(_type.intValue)
                          : adTypeToString(CropDmpAdTypeImage);
    dict[@"width"] = _width ? _width : @(250);
    dict[@"height"] = _height ? _height : @(250);

    return dict;
}

@end // @implementation CropDMPPayloadAdsOptionsData

NSString *adTypeToString(CropDMPAdType type)
{
    switch (type) {
        case CropDmpAdTypeImage: return @"img";
    }

    CropDMPAssert(NO, @"Unexpected ad type: %d", type);
    return nil;
}
