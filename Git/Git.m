//
//  Git.m
//  ObjGit
//

#import "Git.h"
#import "GitObject.h"
#import "GitCommit.h"
#import "GitServerHandler.h"

#include <CommonCrypto/CommonDigest.h>

@implementation Git

@synthesize gitDirectory;

- (id) init 
{
    return self;
}

- (void) dealloc 
{
    [super dealloc];
}

- (BOOL) ensureGitPath {
	BOOL isDir;
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:gitDirectory isDirectory:&isDir] && isDir) {
		return YES;
	} else {
		[self initGitRepo];
	}
	return YES;
}

- (void) initGitRepo {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *dir;
	[fm createDirectoryAtPath:gitDirectory attributes:nil];
	NSLog(@"Dir Created: %@ %d", gitDirectory, [gitDirectory length]);
	
	NSLog(@"Dir: %@", [gitDirectory substringToIndex:([gitDirectory length] - 20)]);

	dir = [gitDirectory stringByAppendingString:@"/refs"];
	NSLog(@"Ref Created: %@]", dir);

	[fm createDirectoryAtPath:dir attributes:nil];
	[fm createDirectoryAtPath:[gitDirectory stringByAppendingPathComponent:@"refs/heads"] attributes:nil];
	[fm createDirectoryAtPath:[gitDirectory stringByAppendingPathComponent:@"refs/tags"] attributes:nil];
	[fm createDirectoryAtPath:[gitDirectory stringByAppendingPathComponent:@"objects"] attributes:nil];
	[fm createDirectoryAtPath:[gitDirectory stringByAppendingPathComponent:@"objects/info"] attributes:nil];
	[fm createDirectoryAtPath:[gitDirectory stringByAppendingPathComponent:@"objects/pack"] attributes:nil];
	[fm createDirectoryAtPath:[gitDirectory stringByAppendingPathComponent:@"branches"] attributes:nil];
	[fm createDirectoryAtPath:[gitDirectory stringByAppendingPathComponent:@"hooks"] attributes:nil];
	[fm createDirectoryAtPath:[gitDirectory stringByAppendingPathComponent:@"info"] attributes:nil];
}

- (NSString *) writeObject:(NSData *)objectData withType:(NSString *)type withSize:(int)size 
{
	NSLog(@"WRITE OBJECT");
	NSMutableData *object;
	NSString *header, *path, *shaStr;
	unsigned char rawsha[20];
	char sha1[41];
	
	header = [NSString stringWithFormat:@"%@ %d", type, size];
	NSLog(@"header: %@", header);
	
	const char *headerBytes = [header cStringUsingEncoding:NSASCIIStringEncoding];
	
	object = [NSMutableData dataWithBytes:headerBytes length:([header length] + 1)];
	[object appendData:objectData];
	
	CC_SHA1([object bytes], [object length], rawsha);
	[Git gitUnpackHex:rawsha fillSha:sha1];
	NSLog(@"SHAR: %s", sha1);

	// write object to file
	shaStr = [NSString stringWithCString:sha1 encoding:NSASCIIStringEncoding];
	path = [self getLooseObjectPathBySha:shaStr];
	[object writeToFile:path atomically:YES];
	return shaStr;
}

- (BOOL) openRepo:(NSString *)dirPath 
{
	gitDirectory = dirPath;
	return YES;
}

- (NSMutableArray *) getCommitsFromSha:(NSString *)shaValue withLimit:(int)commitSize
{
	NSString *currentSha;
	NSMutableArray *toDoArray = [NSMutableArray arrayWithCapacity:10];
	NSMutableArray *commitArray = [NSMutableArray arrayWithCapacity:commitSize];
	GitCommit *gCommit;

	[toDoArray addObject: shaValue];
	
	// loop for commits	
	while( ([toDoArray count] > 0) && ([commitArray count] < commitSize) ) {
		currentSha = [[toDoArray objectAtIndex: 0] retain];
		[toDoArray removeObjectAtIndex:0];
		
		NSString *objectPath = [self getLooseObjectPathBySha:currentSha];
		NSFileHandle *fm = [NSFileHandle fileHandleForReadingAtPath:objectPath];

		gCommit = [[GitCommit alloc] initFromRaw:[fm availableData] withSha:currentSha];
		[toDoArray addObjectsFromArray:gCommit.parentShas];
		[commitArray addObject:gCommit];
	}
	
	// NSLog(@"s: %@", commitArray);
	
	return commitArray;
}

- (NSString *) getLooseObjectPathBySha: (NSString *)shaValue
{
	NSString *looseSubDir   = [shaValue substringWithRange:NSMakeRange(0, 2)];
	NSString *looseFileName = [shaValue substringWithRange:NSMakeRange(2, 38)];
	
	NSString *dir = [NSString stringWithFormat: @"%@/objects/%@", gitDirectory, looseSubDir];
	
	BOOL isDir;
	NSFileManager *fm = [NSFileManager defaultManager];
	if (!([fm fileExistsAtPath:dir isDirectory:&isDir] && isDir)) {
		[fm createDirectoryAtPath:dir attributes:nil];
	}
	
	return [NSString stringWithFormat: @"%@/objects/%@/%@", \
			gitDirectory, looseSubDir, looseFileName];
}


/*
 * returns 1 if the char is alphanumeric, 0 if not 
 */
+ (int) isAlpha:(unsigned char)n 
{
	if(n <= 102 && n >= 97) {
		return 1;
	}
	return 0;
}

/*
 * fills a 40-char string with a readable hex version of 20-char sha binary
 */
+ (int) gitUnpackHex:(const unsigned char *)rawsha fillSha:(char *)sha1
{
	static const char hex[] = "0123456789abcdef";
	int i;

	for (i = 0; i < 20; i++) {          
		unsigned char n = rawsha[i];
		sha1[i * 2] = hex[((n >> 4) & 15)];
		n <<= 4;
		sha1[(i * 2) + 1] = hex[((n >> 4) & 15)];
	}
	sha1[40] = 0;
	
	return 1;   
}

/*
 * fills 20-char sha from 40-char hex version
 */
+ (int) gitPackHex:(const char *)sha1 fillRawSha:(unsigned char *)rawsha
{
	unsigned char byte = 0;
	int i, j = 0;
	
	for (i = 1; i <= 40; i++) {
		unsigned char n = sha1[i - 1];
		
		if([Git isAlpha:n]) {
			byte |= ((n & 15) + 9) & 15;
		} else {
			byte |= (n & 15);
		}
		if(i & 1) {
			byte <<= 4;
		} else {
			rawsha[j] = (byte & 0xff);
			j++;
			byte = 0;
		}
	}
	return 1;
}

@end

