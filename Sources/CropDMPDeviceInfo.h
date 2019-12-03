//
//  CropDMPDeviceInfo.h
//
//  Copyright © 2019 CROP.network. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CropDMPDeviceInfo : NSObject

@property (copy, nonatomic) NSString *deviceLocale;
@property (copy, nonatomic) NSString *appLocale;
@property (copy, nonatomic) NSString *categoryName;
@property (copy, nonatomic) NSDate *firstUseDate;
@property (copy, nonatomic) NSDate *lastUseDate;
@property (copy, nonatomic) NSNumber *numberOfUses;

@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *manufacturer;
@property (copy, nonatomic) NSString *model;
@property (copy, nonatomic) NSString *brand;
@property (copy, nonatomic) NSString *os;
@property (copy, nonatomic) NSValue *screenSizePixels;
@property (copy, nonatomic) NSNumber *ramSizeBytes;
@property (copy, nonatomic) NSNumber *hddSizeBytes;
@property (copy, nonatomic) NSString *manufacturerCountryISOID;
@property (copy, nonatomic) NSDate *productionDate;
@property (copy, nonatomic) NSString *productionDateString; // If structured date not present
@property (copy, nonatomic) NSString *cellNumber; // Will be hashed upon serialization
@property (copy, nonatomic) NSString *cellEMEI; // Will be hashed upon serialization

- (NSDictionary *)toDictionary;

@end
