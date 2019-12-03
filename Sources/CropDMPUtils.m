//
//  CropDMPUtils.m
//
//  Copyright © 2019 CROP.network. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

#import "CropDMPUtils.h"

static char hexDigitFromValue(char i) {
    if (i > 9)
        return 'a' + (i - 10);

    return '0' + i;
}

@implementation CropDMPUtils

+ (NSString *)md5FromData:(NSData *)data
{
    unsigned char md5[CC_MD5_DIGEST_LENGTH];
    CC_MD5((const char *)data.bytes, (CC_LONG)data.length, md5);

    return [self bytesToHex:md5 size:CC_MD5_DIGEST_LENGTH];
}

+ (NSString *)sha256FromData:(NSData *)data
{
    unsigned char sha256[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256((const char *)data.bytes, (CC_LONG)data.length, sha256);

    return [self bytesToHex:sha256 size:CC_SHA256_DIGEST_LENGTH];
}

+ (NSString *)hashPersonalString:(NSString *)personalString
{
    return [self sha256FromData:[personalString dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSString *)bytesToHex:(const unsigned char *)bytes size:(int)size {
    const int hexLength = size * 2;
    char *hex = (char *)malloc(hexLength);

    for (int i = 0; i < size; ++i) {
        hex[i * 2] = hexDigitFromValue((bytes[i] >> 4) & 0xf);
        hex[i * 2 + 1] = hexDigitFromValue(bytes[i] & 0xf);
    }

    return [[NSString alloc] initWithBytesNoCopy:hex length:hexLength encoding:NSASCIIStringEncoding freeWhenDone:YES];
}

@end
