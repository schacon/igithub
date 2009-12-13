//
//  NSData+Hashing.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 29/06/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//
//  Methods extracted from source given at
//  http://www.cocoadev.com/index.pl?NSDataCategory
//
//  The original NSDataCategory used OpenSSL for the
//  hashing. This has been switched to CommonCrypto
//  due to its availability on both iPhone and Mac OS.
//

#import "NSData+Hashing.h"
#include <CommonCrypto/CommonDigest.h>

@implementation NSData (Hashing)

#pragma mark -
#pragma mark Hashing macros
#define HEComputeDigest(method)                                         \
    CC_##method##_CTX ctx;                                              \
    unsigned char digest[CC_##method##_DIGEST_LENGTH];                  \
    CC_##method##_Init(&ctx);                                           \
    CC_##method##_Update(&ctx, [self bytes], [self length]);            \
    CC_##method##_Final(digest, &ctx);

#define HEComputeDigestNSData(method)                                   \
    HEComputeDigest(method)                                             \
    return [NSData dataWithBytes:digest length:CC_##method##_DIGEST_LENGTH];

#define HEComputeDigestNSString(method)                                 \
    static char __HEHexDigits[] = "0123456789abcdef";                   \
    unsigned char digestString[2*CC_##method##_DIGEST_LENGTH];          \
    unsigned int i;                                                     \
    HEComputeDigest(method)                                             \
    for(i=0; i<CC_##method##_DIGEST_LENGTH; i++) {                      \
        digestString[2*i]   = __HEHexDigits[digest[i] >> 4];            \
        digestString[2*i+1] = __HEHexDigits[digest[i] & 0x0f];          \
    }                                                                   \
    return [NSString stringWithCString:(char *)digestString length:2*CC_##method##_DIGEST_LENGTH];

#pragma mark -
#pragma mark SHA1 Hashing routines
- (NSData*) sha1Digest
{
	HEComputeDigestNSData(SHA1);
}
- (NSString*) sha1DigestString
{
	HEComputeDigestNSString(SHA1);
}

@end
