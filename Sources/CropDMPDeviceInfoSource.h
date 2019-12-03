//
//  CropDMPDeviceInfoSource.h
//
//  Copyright © 2019 CROP.network. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CropDMPDeviceInfoSource;
@protocol CropDMPDeviceInfoSourceDelegate

- (void)cropDMPDeviceInfoSource:(id<CropDMPDeviceInfoSource>)source
             deviceInfosChanged:(NSArray *)deviceInfo;

@end // @protocol CropDMPDeviceInfoDelegate

@protocol CropDMPDeviceInfoSource <NSObject>

@property (readonly, nonatomic) NSArray *deviceInfos; // Array of CropDMPDeviceInfo objects
@property (weak, nonatomic) id<CropDMPDeviceInfoSourceDelegate> delegate;

@end
