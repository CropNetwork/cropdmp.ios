//
//  CropDMPDeviceInfo.m
//
//  Copyright © 2019 CROP.network. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CropDMPDeviceInfo.h"
#import "CropDMPUtils.h"

@interface NSMutableDictionary (CropDMPSetIfNotNil)
- (void)setValueIfNotNil:(id)value forKey:(NSString *)key;
@end

@implementation CropDMPDeviceInfo

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:[self characteristicsDict] forKey:@"characteristics"];
    [dict setValueIfNotNil:_deviceLocale forKey:@"deviceLocale"];
    [dict setValueIfNotNil:_appLocale forKey:@"appLocale"];
    [dict setValueIfNotNil:_categoryName forKey:@"categoryName"];
    [dict setValueIfNotNil:[self iso8601StringOrNil:_firstUseDate]
                        forKey:@"firstUseDate"];
    [dict setValueIfNotNil:[self iso8601StringOrNil:_lastUseDate]
                        forKey:@"lastUseDate"];
    [dict setValueIfNotNil:_numberOfUses forKey:@"numberOfUses"];

    return dict;
}

- (NSDictionary *)characteristicsDict
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValueIfNotNil:_name forKey:@"name"];
    [dict setValueIfNotNil:_manufacturer forKey:@"manufacturer"];
    [dict setValueIfNotNil:_model forKey:@"model"];
    [dict setValueIfNotNil:_brand forKey:@"brand"];
    [dict setValueIfNotNil:_os forKey:@"os"];
    [dict setValueIfNotNil:[self screenSizeDict] forKey:@"screenSize"];
    [dict setValueIfNotNil:[self memoryDict] forKey:@"deviceMemory"];
    [dict setValueIfNotNil:_manufacturerCountryISOID forKey:@"madeIn"];
    [dict setValueIfNotNil:[self productionDateString]
                                forKey:@"productionDate"];
    [dict setValueIfNotNil:[self hashPersonalStringOrNil:_cellNumber]
                                forKey:@"cellNumber"];
    [dict setValueIfNotNil:[self hashPersonalStringOrNil:_cellEMEI]
                                forKey:@"cellEmei"];
    return dict;
}

- (NSDictionary *)memoryDict
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValueIfNotNil:_ramSizeBytes forKey:@"ram"];
    [dict setValueIfNotNil:_hddSizeBytes forKey:@"drive"];
    return dict;
}

- (NSDictionary *)screenSizeDict
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValueIfNotNil:@(_screenSizePixels.CGSizeValue.width) forKey:@"width"];
    [dict setValueIfNotNil:@(_screenSizePixels.CGSizeValue.height) forKey:@"height"];
    return dict;
}

- (NSString *)productionDateString
{
    if (!_productionDate)
        return _productionDateString;

    return [self iso8601StringOrNil:_productionDate];
}

- (NSString *)hashPersonalStringOrNil:(NSString *)stringOrNil
{
    if (!stringOrNil)
        return nil;

    return [CropDMPUtils hashPersonalString:stringOrNil];
}

- (NSString *)iso8601StringOrNil:(NSDate *)dateOrNil
{
    if (!dateOrNil)
        return nil;

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

    return [dateFormatter stringFromDate:dateOrNil];
}

@end // @implementation CropDMPDeviceInfo

@implementation NSMutableDictionary (CropDMPSetIfNotNil)

- (void)setValueIfNotNil:(id)value forKey:(NSString *)key
{
    if (!value)
        return;

    [self setValue:value forKey:key];
}

@end // @implementation NSMutableDictionary (CropDMPSetIfNotNil)
