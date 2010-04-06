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

// pre-calculated hex value (v) -> strchr(hexchars, v) - hexchars
// to save searching the string on each iteration
static signed char from_hex[256] = {
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 00 */
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 10 */
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 20 */
 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, -1, -1, -1, -1, -1, -1, /* 30 */
-1, 10, 11, 12, 13, 14, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 40 */
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 50 */
-1, 10, 11, 12, 13, 14, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 60 */
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 70 */
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 80 */
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 90 */
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* a0 */
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* b0 */
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* c0 */
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* d0 */
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* e0 */
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* f0 */
};

NSData *
packSHA1FromBytes(const char *hexBytes)
{
    NSMutableData *packedSHA1 = [NSMutableData dataWithLength:kGITPackedSha1Length];
    uint8_t *packedBytes = [packedSHA1 mutableBytes];
    int i;
    for ( i = 0; i < kGITPackedSha1Length; i++, hexBytes += 2) {
        NSUInteger bits = (from_hex[hexBytes[0]] << 4) | (from_hex[hexBytes[1]]);
        if ( bits < 0 ) {
            return nil;
        }
        packedBytes[i] = (unsigned char)bits;
    }
    return packedSHA1;
}

NSData *
packSHA1(NSString * unpackedSHA1)
{
    return packSHA1FromBytes([unpackedSHA1 cStringUsingEncoding:NSASCIIStringEncoding]);
}

NSString *
unpackSHA1FromString(NSString * packedSHA1)
{
    uint8_t bits;
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
    return unpackSHA1FromBytes((const uint8_t *)[packedSHA1 bytes], [packedSHA1 length]);
}

NSString *
unpackSHA1FromBytes(const uint8_t * bytes, unsigned int length)
{
    NSMutableData *unpackedSHA1 = [NSMutableData dataWithLength:kGITUnpackedSha1Length];
    uint8_t *unpackedBytes = [unpackedSHA1 mutableBytes];
    int i;
    for(i = 0; i < length; i++)
    {
        *unpackedBytes++ = hexchars[bytes[i] >> 4];
        *unpackedBytes++ = hexchars[bytes[i] & 0xf];
    }
    return [[[NSString alloc] initWithData:unpackedSHA1 encoding:NSASCIIStringEncoding] autorelease];
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
