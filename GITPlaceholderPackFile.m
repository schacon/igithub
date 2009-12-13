//
//  GITPlaceholderPackFile.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 04/11/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITPlaceholderPackFile.h"
#import "GITUtilityBelt.h"

static const char const kGITPackFileSignature[] = {'P', 'A', 'C', 'K'};

//            Name of Range                 Start   Length
const NSRange kGITPackFileSignatureRange = {     0,      4 };
const NSRange kGITPackFileVersionRange   = {     4,      4 };

@implementation GITPlaceholderPackFile

- (id)initWithData:(NSData*)packData error:(NSError **)error;
{	
    if (! packData)
        return nil;
    
    uint8_t buf[4];
    NSUInteger ver;
    NSString * errorDescription;
    NSZone * z = [self zone];
    [self release];

    [packData getBytes:buf range:kGITPackFileSignatureRange];
    if (memcmp(buf, kGITPackFileSignature, kGITPackFileSignatureRange.length) != 0) {
		//NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Data is not valid PACK format", "GITErrorPackFileInvalid"), thePath];
		GITError(error, GITErrorPackFileInvalid, NSLocalizedString(@"Data is not valid PACK format", "GITErrorPackFileInvalid"));
		return nil;
	}
	
	// Its a valid PACK file
	memset(buf, 0x0, kGITPackFileSignatureRange.length);
	[packData getBytes:buf range:kGITPackFileVersionRange];
	ver = integerFromBytes(buf, kGITPackFileVersionRange.length);
    
	switch (ver)
	{
		case 2:
			return [[GITPackFileVersion2 allocWithZone:z] initWithData:packData error:error];
		default:
			errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Pack version %lu not supported", @"GITErrorPackFileNotSupported"), ver];
			GITError(error, GITErrorPackFileNotSupported, errorDescription);
			return nil;
	}
}

- (id)initWithPath:(NSString*)thePath error:(NSError **)error
{	
    uint8_t buf[4];
    NSUInteger ver;
    NSString * errorDescription;
    NSZone * z = [self zone]; [self release];
    NSData * data = [NSData dataWithContentsOfFile:thePath
                                           options:NSUncachedRead
                                             error:error];
    if (!data)
		return nil;
    
    // File opened successfully
    [data getBytes:buf range:kGITPackFileSignatureRange];
    if (memcmp(buf, kGITPackFileSignature, kGITPackFileSignatureRange.length) != 0) {
		NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"File %@ is not a PACK file", "GITErrorPackFileInvalid"), thePath];
		GITError(error, GITErrorPackFileInvalid, errorDescription);
		return nil;
	}
	
	// Its a valid PACK file
	memset(buf, 0x0, kGITPackFileSignatureRange.length);
	[data getBytes:buf range:kGITPackFileVersionRange];
	ver = integerFromBytes(buf, kGITPackFileVersionRange.length);

	switch (ver)
	{
		case 2:
			return [[GITPackFileVersion2 allocWithZone:z] initWithPath:thePath error:error];
		default:
			errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Pack version %lu not supported", @"GITErrorPackFileNotSupported"), ver];
			GITError(error, GITErrorPackFileNotSupported, errorDescription);
			return nil;
	}
}
@end
