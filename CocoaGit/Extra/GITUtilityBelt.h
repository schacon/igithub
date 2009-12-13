//
//  GITUtilityBelt.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 12/08/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NSData * packSHA1FromBytes(const char *hexBytes);
NSData   * packSHA1(NSString * unpackedSHA1);
NSString * unpackSHA1FromString(NSString * packedSHA1);
NSString * unpackSHA1FromData(NSData * packedSHA1);
NSString * unpackSHA1FromBytes(const uint8_t * bytes, unsigned int length);
BOOL isSha1StringValid(NSString *shaString);
NSData   * bytesToData(const uint8_t *bytes, unsigned int length);
NSUInteger integerFromBytes(uint8_t * bytes, NSUInteger length);
NSData * intToHexLength(NSUInteger length);
NSUInteger hexLengthToInt(NSData *lengthData);