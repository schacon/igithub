//
//  GITPlaceholderPackIndex.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 04/11/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITPlaceholderPackIndex.h"
#import "GITUtilityBelt.h"
#import "GITErrors.h"

static const char const kGITPackIndexMagicNumber[] = { '\377', 't', 'O', 'c' };

@implementation GITPlaceholderPackIndex
- (id)initWithPath:(NSString*)thePath error:(NSError**)outError
{
    uint8_t buf[4];
    NSUInteger ver;
    NSString * description;
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSZone * z = [self zone]; [self release];

	if (! [fileManager isReadableFileAtPath:thePath]) {
		description = [NSString stringWithFormat:NSLocalizedString(@"File %@ not found",@"GITErrorFileNotFound (GITPackIndex)"), thePath];
		GITError(outError, GITErrorFileNotFound, description);
		return nil;
	}
			
	NSData * data = [NSData dataWithContentsOfFile:thePath
										   options:NSUncachedRead
											 error:outError];
	if (!data) // Another type of error occurred
		return nil;
	
	// File opened successfully, read the first four bytes to see if
	// we are a version 1 index or a later version index.
	[data getBytes:buf range:NSMakeRange(0, 4)];
	if (memcmp(buf, kGITPackIndexMagicNumber, 4) != 0)
		return [[GITPackIndexVersion1 allocWithZone:z] initWithPath:thePath error:outError];
	
	// Its a v2+ index file
	memset(buf, 0x0, 4);
	[data getBytes:buf range:NSMakeRange(4, 4)];
	ver = integerFromBytes(buf, 4);
	
	switch (ver)
	{
		case 2:
			return [[GITPackIndexVersion2 allocWithZone:z] initWithPath:thePath error:outError];
		default:
			description = [NSString stringWithFormat:NSLocalizedString(@"Pack Index version %lu is not supported",@"GITErrorPackIndexUnsupportedVersion"), ver];
			GITError(outError, GITErrorPackIndexUnsupportedVersion, description);
			return nil;
	}
}
@end