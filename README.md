# CROP DMP iOS Lib

## Usage

1. Add files from CropDMP to the project
    - Add ArkMN, Chromecast and iOS directories under CropDMP if you want to collect device info from the corresponding sources.
2. Initialize CropDMP and perform the first request in `-[AppDelegate application:didFinishLaunchingWithOptions:]`

```objc
        [CropDMP initializeWithAPIKey:apiKey];

        CropDMP *cropDMP = [CropDMP sharedInstance];
        cropDMP.enableExtensiveLogging = YES;
        cropDMP.sendAllDeviceInfosUponChange = YES;
        [cropDMP addDeviceInfoSource:[[CropDMPThisDeviceInfoSource alloc] init]];
        [cropDMP addDeviceInfoSource:[[CropDMPChromecastDeviceInfoSource alloc] init]];
        [cropDMP sendAllDeviceInfos];
```

3. Subscribe to banner URL updates:

```objc
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(onCropDMPReceivedBannerURL)
                   name:CropDMPReceivedBannerURLNotification
                 object:[CropDMP sharedInstance]];
    [center addObserver:self
               selector:@selector(onCropDMPFailedToReceivedBannerURL)
                   name:CropDMPFailedToReceiveBannerURLNotification
                 object:[CropDMP sharedInstance]];
```

4. Retrieve banner URL:

```objc
- (void)onCropDMPReceivedBannerURL
{
    NSURL *bannerURL = [NSURL URLWithString:[CropDMP sharedInstance].bannerURL];
    if (!bannerURL)
        return;

    // Use banner URL
}
```
