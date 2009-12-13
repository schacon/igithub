//
//  GITFileStore.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 07/10/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITFileStore.h"
#import "NSData+Compression.h"
#import "NSData+Searching.h"
#import "GITObject.h"

/*! \cond */
@interface GITFileStore ()
@property(readwrite,copy) NSString * objectsDir;
@end
/*! \endcond */

@implementation GITFileStore
@synthesize objectsDir;

- (void) dealloc
{
    [objectsDir release], objectsDir = nil;
    [super dealloc];
}

- (id)initWithRoot:(NSString*)root
{
    if (! [super init])
        return nil;

    self.objectsDir = [root stringByAppendingPathComponent:@"objects"];
    return self;
}

- (id)initWithRoot:(NSString*)root error:(NSError**)error
{
    if (! [super init])
        return nil;

    self.objectsDir = [root stringByAppendingPathComponent:@"objects"];

    BOOL aDirectory;
    NSFileManager * fm = [NSFileManager defaultManager];
    if (! [fm fileExistsAtPath:self.objectsDir isDirectory:&aDirectory] || !aDirectory) {
        NSString * errFmt = NSLocalizedString(@"File store not accessible %@ does not exist or is not a directory", @"GITErrorObjectStoreNotAccessible (GITFileStore)");
        NSString * errDesc = [NSString stringWithFormat:errFmt, self.objectsDir];
        GITError(error, GITErrorObjectStoreNotAccessible, errDesc);
        [self release];
        return nil;
    }

    return self;
}
- (NSString*)stringWithPathToObject:(NSString*)sha1
{
    NSString * ref = [NSString stringWithFormat:@"%@/%@",
                      [sha1 substringToIndex:2], [sha1 substringFromIndex:2]];
    
    return [self.objectsDir stringByAppendingPathComponent:ref];
}
- (NSData*)dataWithContentsOfObject:(NSString*)sha1
{
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * path = [self stringWithPathToObject:sha1];

    if ([fm isReadableFileAtPath:path])
    {
        NSData * zlibData = [NSData dataWithContentsOfFile:path];
        return [zlibData zlibInflate];
    }

    return nil;
}
- (BOOL)loadObjectWithSha1:(NSString*)sha1 intoData:(NSData**)data
                      type:(GITObjectType*)type error:(NSError**)error
{
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * path = [self stringWithPathToObject:sha1];
	
	if (![fm isReadableFileAtPath:path]) {
		NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Object %@ not found", @"GITErrorObjectNotFound"), sha1];
		GITError(error, GITErrorObjectNotFound, errorDescription);
		return NO;
	}

	NSData * zlibData = [NSData dataWithContentsOfFile:path options:NSUncachedRead error:error];
	NSData * raw = [zlibData zlibInflate];
	
	NSRange range = [raw rangeOfNullTerminatedBytesFrom:0];
	NSData * meta = [raw subdataWithRange:range];
	*data = [raw subdataFromIndex:range.length + 1];
	
	NSString * metaStr = [[NSString alloc] initWithData:meta
											   encoding:NSASCIIStringEncoding];
	NSUInteger indexOfSpace = [metaStr rangeOfString:@" "].location;
	NSInteger size = [[metaStr substringFromIndex:indexOfSpace + 1] integerValue];
	
	// This needs to be a GITObjectType value instead of a string
	NSString * typeStr = [metaStr substringToIndex:indexOfSpace];
	*type = [GITObject objectTypeForString:typeStr];
	[metaStr release];

	// We could check *data and *type individually, and bail with a more specific error if they are nil.
	if (! (*data && *type && size == [*data length])) {
		GITError(error, GITErrorObjectSizeMismatch, NSLocalizedString(@"Object size mismatch", @"GITErrorObjectSizeMismatch"));
		return NO;
	}

	return YES;
}
@end
