//
//  CropDMPPayload.h
//
//  Copyright © 2019 CROP.network. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CropDMPPayloadCommonData;
@class CropDMPPayloadHashData;
@class CropDMPPayloadAdsOptionsData;
@class CropDMPDeviceInfo;

@interface CropDMPPayload : NSObject

@property (readonly, nonatomic) CropDMPPayloadCommonData *commonData;
@property (readonly, nonatomic) CropDMPPayloadHashData *hashData;
@property (readonly, nonatomic) CropDMPPayloadAdsOptionsData *adsOptionsData;

- (NSDictionary *)toDictionary;

@end // @interface CropDMPPayload

@interface CropDMPPayloadCommonData : NSObject

@property (copy, nonatomic) NSArray *deviceInfos;
@property (copy, nonatomic) NSString *cellEmei;

- (NSDictionary *)toDictionary;

@end // @interface CropDMPPayloadCommonData

@interface CropDMPPayloadHashData : NSObject

- (NSDictionary *)toDictionary;

@end // @interface CropDMPPayloadHashData

typedef enum CropDMPAdType {
    CropDmpAdTypeImage
} CropDMPAdType;
@interface CropDMPPayloadAdsOptionsData : NSObject

@property (assign, nonatomic) NSNumber *type; // CropDMPAdType
@property (assign, nonatomic) NSNumber *width;
@property (assign, nonatomic) NSNumber *height;

- (NSDictionary *)toDictionary;

@end // @interface CropDMPPayloadAdsOptionsData
