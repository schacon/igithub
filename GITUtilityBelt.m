//
//  GITUtilityBelt.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 12/08/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITUtilityBelt.h"
#import <arpa/inet.h>

const NSUInteger kGITPackedSha1Length   = 20;
const NSUInteger kGITUnpackedSha1Length = 40;

static const char hexchars[] = "0123456789abcdef";

NSData *
packSHA1(NSString * unpackedSHA1)
{
    unsigned int highBits, lowBits, bits;
    NSMutableData *packedSHA1 = [NSMutableData dataWithCapacity:kGITPackedSha1Length];
    int i;
    for (i = 0; i < [unpackedSHA1 length]; i++)
    {
        if (i % 2 == 0) {
            highBits = (strchr(hexchars, [unpackedSHA1 characterAtIndex:i]) - hexchars) << 4;
        } else {
            lowBits = strchr(hexchars, [unpackedSHA1 characterAtIndex:i]) - hexchars;
            bits = (highBits | lowBits);
            [packedSHA1 appendBytes:&bits length:1];
        }
    }
    return [NSData dataWithData:packedSHA1];
}

NSString *
unpackSHA1FromString(NSString * packedSHA1)
{
    unsigned int bits;
    NSMutableString *unpackedSHA1 = [NSMutableString stringWithCapacity:kGITUnpackedSha1Length];
    int i;
    for(i = 0; i < kGITPackedSha1Length; i++)
    {
        bits = [packedSHA1 characterAtIndex:i];
        [unpackedSHA1 appendFormat:@"%c", hexchars[bits >> 4]];
        [unpackedSHA1 appendFormat:@"%c", hexchars[bits & 0xf]];
    }
    return [NSString stringWithString:unpackedSHA1];
}

NSString *
unpackSHA1FromData(NSData * packedSHA1)
{
    uint8_t bits;
    NSMutableString *unpackedSHA1 = [NSMutableString stringWithCapacity:kGITUnpackedSha1Length];
    int i;
    for(i = 0; i < kGITPackedSha1Length; i++)
    {
        [packedSHA1 getBytes:&bits range:NSMakeRange(i, 1)];
        [unpackedSHA1 appendFormat:@"%c", hexchars[bits >> 4]];
        [unpackedSHA1 appendFormat:@"%c", hexchars[bits & 0xf]];
    }
    return [NSString stringWithString:unpackedSHA1];
}

NSString *
unpackSHA1FromBytes(const uint8_t * bytes, unsigned int length)
{
    NSData * data;
    if (length < 0)
        return nil;
    data = [NSData dataWithBytes:bytes length:length];
    return unpackSHA1FromData(data);
}

BOOL
isSha1StringValid(NSString *shaString)
{
    if ([shaString length] != 40)
        return NO;

    const char *bytes = [shaString UTF8String];    
    const char *p = bytes;
    while ( *p >= '0' && *p <= 'f' )
        p++;

    return ((p - bytes) == 40);
}

NSData *
bytesToData(const uint8_t *bytes, unsigned int length)
{
    if (length < 0)
        return nil;    
    return [NSData dataWithBytes:bytes length:length];
}

NSUInteger
integerFromBytes(uint8_t * bytes, NSUInteger length)
{
    NSUInteger i, value = 0;
    for (i = 0; i < length; i++)
        value = (value << 8) | bytes[i];
    return value;
}

// Encode  as a 4-byte hex value
#define hex(a) (hexchars[(a) & 15])
NSData *
intToHexLength(NSUInteger length) 
{
	uint8_t buffer[4];
	
	buffer[0] = hex(length >> 12);
	buffer[1] = hex(length >> 8);
	buffer[2] = hex(length >> 4);
	buffer[3] = hex(length);
	
    return [NSData dataWithBytes:buffer length:4];
}

NSUInteger
hexLengthToInt(NSData *lengthData)
{
	uint8_t linelen[4];
	[lengthData getBytes:linelen length:4];
    
	NSUInteger len = 0;
	int n;
	for (n = 0; n < 4; n++) {
		uint8_t c = linelen[n];
		len <<= 4;
		if (c >= '0' && c <= '9') {
			len += c - '0';
			continue;
		}
		if (c >= 'a' && c <= 'f') {
			len += c - 'a' + 10;
			continue;
		}
		if (c >= 'A' && c <= 'F') {
			len += c - 'A' + 10;
			continue;
		}
        // error: bad character, return -1 so that the caller knows there is a problem
        return -1;
	}
	
	return len;
}
