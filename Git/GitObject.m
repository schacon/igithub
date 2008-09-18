//
//  GitObject.m
//  ObjGit
//

#import "GitObject.h"
#import "NSDataCompression.h"

@implementation GitObject

@synthesize sha;
@synthesize size;
@synthesize type;
@synthesize contents;
@synthesize raw;

- (id) initFromRaw:(NSData *)rawData withSha:(NSString *)shaValue
{
	self = [super init];	
	sha = shaValue;
	raw = [self inflateRaw:rawData];
	// NSLog(@"sha: %@", sha);
	// NSLog(@"raw: %@", raw);
	[self parseRaw];
	return self;
}

- (void) parseRaw
{
	char *ptr, *bytes = (char *)[raw bytes]; 
    int len, rest;
    len = (ptr = memchr(bytes, nil, len = [raw length])) ? ptr - bytes : len;
	rest = [raw length] - len;
	
	ptr++;
    NSString *header   = [NSString stringWithCString:bytes length:len];
    contents = [NSString stringWithCString:ptr length:rest];

	NSArray *headerData = [header componentsSeparatedByString:@" "];
	type =  [headerData objectAtIndex:0];
	size = [[headerData objectAtIndex:1] intValue];
	
	//NSLog(@"type:%@", type);
	//NSLog(@"len:%d", size);
	//NSLog(@"con:%@", contents);
}

- (NSData *) inflateRaw:(NSData *)rawData
{
	return [rawData decompressedData];
}

@end
