//
//  ObjGitObject.m
//  ObjGit
//

#import "ObjGitObject.h"
#import "NSDataCompression.h"

@implementation ObjGitObject

@synthesize sha;
@synthesize size;
@synthesize type;
@synthesize contents;
@synthesize raw;
@synthesize rawContents;
@synthesize rawContentLen;

- (id) initFromRaw:(NSData *)rawData withSha:(NSString *)shaValue
{
	self = [super init];	
	sha = shaValue;
	raw = [self inflateRaw:rawData];
	// NSLog(@"init sha: %@", sha);
	// NSLog(@"raw: %@", raw);
	[self parseRaw];
	return self;
}

- (void) parseRaw
{
	char *ptr, *bytes = (char *)[raw bytes]; 
    int len, rest;
    len = (ptr = memchr(bytes, nil, len = [raw length])) ? ptr - bytes : len;
	rest = [raw length] - len - 1;
	
	ptr++;
    NSString *header   = [NSString stringWithCString:bytes length:len];
    contents = [NSString stringWithCString:ptr length:rest];
	
	rawContents = malloc(rest);
	memcpy(rawContents, ptr, rest);
	rawContentLen = rest;
	
	NSArray *headerData = [header componentsSeparatedByString:@" "];
	
	type =  [headerData objectAtIndex:0];
	size = [[headerData objectAtIndex:1] intValue];
}

- (NSData *) inflateRaw:(NSData *)rawData
{
	return [rawData decompressedData];
}

@end
