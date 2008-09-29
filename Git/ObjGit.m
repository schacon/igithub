//
//  ObjGit.m
//  ObjGit
//

#import "ObjGit.h"
#import "ObjGitObject.h"
#import "ObjGitCommit.h"
#import "ObjGitServerHandler.h"
#import "NSDataCompression.h"

#include <CommonCrypto/CommonDigest.h>

@implementation ObjGit

@synthesize gitDirectory;
@synthesize gitName;

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
	if ([fm fileExistsAtPath:self.gitDirectory isDirectory:&isDir] && isDir) {
		return YES;
	} else {
		[self initGitRepo];
	}
	return YES;
}

- (NSArray *) getAllRefs 
{
	BOOL isDir=NO;
	NSMutableArray *refsFinal = [[NSMutableArray alloc] init];
	NSString *tempRef, *thisSha;
	NSString *refsPath = [self.gitDirectory stringByAppendingPathComponent:@"refs"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:refsPath isDirectory:&isDir] && isDir) {
		NSEnumerator *e = [[fileManager subpathsAtPath:refsPath] objectEnumerator];
		NSString *thisRef;
		while ( (thisRef = [e nextObject]) ) {
			tempRef = [refsPath stringByAppendingPathComponent:thisRef];
			thisRef = [@"refs" stringByAppendingPathComponent:thisRef];

			if ([fileManager fileExistsAtPath:tempRef isDirectory:&isDir] && !isDir) {
				thisSha = [NSString stringWithContentsOfFile:tempRef encoding:NSASCIIStringEncoding error:nil];
				[refsFinal addObject:[NSArray arrayWithObjects:thisRef,thisSha,nil]];
				if([thisRef isEqualToString:@"refs/heads/master"])
					[refsFinal addObject:[NSArray arrayWithObjects:@"HEAD",thisSha,nil]];
			}
		}
	}
	return refsFinal;
}

- (void) updateRef:(NSString *)refName toSha:(NSString *)toSha
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *refPath = [self.gitDirectory stringByAppendingPathComponent:refName];
	[fm createFileAtPath:refPath contents:[NSData dataWithBytes:[toSha UTF8String] length:[toSha length]] attributes:nil];
}

- (void) initGitRepo {
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm createDirectoryAtPath:self.gitDirectory attributes:nil];

	//NSLog(@"Dir Created: %@ %d", gitDirectory, [gitDirectory length]);
	NSString *config = @"[core]\n\trepositoryformatversion = 0\n\tfilemode = true\n\tbare = true\n\tlogallrefupdates = true\n";
	NSString *configFile = [self.gitDirectory stringByAppendingPathComponent:@"config"];
	[fm createFileAtPath:configFile contents:[NSData dataWithBytes:[config UTF8String] length:[config length]] attributes:nil];

	NSString *head = @"ref: refs/heads/master\n";
	NSString *headFile = [self.gitDirectory stringByAppendingPathComponent:@"HEAD"];
	[fm createFileAtPath:headFile contents:[NSData dataWithBytes:[head UTF8String] length:[head length]] attributes:nil];

	[fm createDirectoryAtPath:[self.gitDirectory stringByAppendingPathComponent:@"refs"] attributes:nil];
	[fm createDirectoryAtPath:[self.gitDirectory stringByAppendingPathComponent:@"refs/heads"] attributes:nil];
	[fm createDirectoryAtPath:[self.gitDirectory stringByAppendingPathComponent:@"refs/tags"] attributes:nil];
	[fm createDirectoryAtPath:[self.gitDirectory stringByAppendingPathComponent:@"objects"] attributes:nil];
	[fm createDirectoryAtPath:[self.gitDirectory stringByAppendingPathComponent:@"objects/info"] attributes:nil];
	[fm createDirectoryAtPath:[self.gitDirectory stringByAppendingPathComponent:@"objects/pack"] attributes:nil];
	[fm createDirectoryAtPath:[self.gitDirectory stringByAppendingPathComponent:@"branches"] attributes:nil];
	[fm createDirectoryAtPath:[self.gitDirectory stringByAppendingPathComponent:@"hooks"] attributes:nil];
	[fm createDirectoryAtPath:[self.gitDirectory stringByAppendingPathComponent:@"info"] attributes:nil];
}

- (NSString *) writeObject:(NSData *)objectData withType:(NSString *)type withSize:(int)size 
{
	NSMutableData *object;
	NSString *header, *path, *shaStr;
	unsigned char rawsha[20];
	char sha1[41];
	
	header = [NSString stringWithFormat:@"%@ %d", type, size];	
	const char *headerBytes = [header cStringUsingEncoding:NSASCIIStringEncoding];
	
	object = [NSMutableData dataWithBytes:headerBytes length:([header length] + 1)];
	[object appendData:objectData];
	
	CC_SHA1([object bytes], [object length], rawsha);
	[ObjGit gitUnpackHex:rawsha fillSha:sha1];
	NSLog(@"WRITING SHA: %s", sha1);

	// write object to file
	shaStr = [NSString stringWithCString:sha1 encoding:NSASCIIStringEncoding];
	path = [self getLooseObjectPathBySha:shaStr];
	NSData *compress = [[NSData dataWithBytes:[object bytes] length:[object length]] compressedData];
	[compress writeToFile:path atomically:YES];
	return shaStr;
}

- (BOOL) openRepo:(NSString *)dirPath 
{
	self.gitDirectory = dirPath;
	return YES;
}

- (NSMutableArray *) getCommitsFromSha:(NSString *)shaValue withLimit:(int)commitSize
{
	NSString *currentSha;
	NSMutableArray *toDoArray = [NSMutableArray arrayWithCapacity:10];
	NSMutableArray *commitArray = [NSMutableArray arrayWithCapacity:commitSize];
	ObjGitCommit *gCommit;

	[toDoArray addObject: shaValue];
	
	// loop for commits	
	while( ([toDoArray count] > 0) && ([commitArray count] < commitSize) ) {
		currentSha = [[toDoArray objectAtIndex: 0] retain];
		[toDoArray removeObjectAtIndex:0];
		
		NSString *objectPath = [self getLooseObjectPathBySha:currentSha];
		NSFileHandle *fm = [NSFileHandle fileHandleForReadingAtPath:objectPath];

		gCommit = [[ObjGitCommit alloc] initFromRaw:[fm availableData] withSha:currentSha];
		
		[toDoArray addObjectsFromArray:gCommit.parentShas];
		[commitArray addObject:gCommit];
	}
	
	// NSLog(@"s: %@", commitArray);
	//[toDoArray release];
	return commitArray;
}

- (ObjGitObject *) getObjectFromSha:(NSString *)sha1 
{
	NSString *objectPath = [self getLooseObjectPathBySha:sha1];
	//NSLog(@"READ FROM FILE: %@", objectPath);
	NSFileHandle *fm = [NSFileHandle fileHandleForReadingAtPath:objectPath];
	ObjGitObject *obj = [[ObjGitObject alloc] initFromRaw:[fm availableData] withSha:sha1];
	[fm closeFile];
	return obj;	
}

- (BOOL) hasObject: (NSString *)sha1 
{
	NSString *path;
	path = [self getLooseObjectPathBySha:sha1];
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:path]) {
		return YES;
	} else {
		// TODO : check packs
	}
	return NO;
}

- (NSString *) getLooseObjectPathBySha: (NSString *)shaValue
{
	NSString *looseSubDir   = [shaValue substringWithRange:NSMakeRange(0, 2)];
	NSString *looseFileName = [shaValue substringWithRange:NSMakeRange(2, 38)];
	
	NSString *dir = [NSString stringWithFormat: @"%@/objects/%@", self.gitDirectory, looseSubDir];
	
	BOOL isDir;
	NSFileManager *fm = [NSFileManager defaultManager];
	if (!([fm fileExistsAtPath:dir isDirectory:&isDir] && isDir)) {
		[fm createDirectoryAtPath:dir attributes:nil];
	}
	
	return [NSString stringWithFormat: @"%@/objects/%@/%@", \
			self.gitDirectory, looseSubDir, looseFileName];
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
		
		if([ObjGit isAlpha:n]) {
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

