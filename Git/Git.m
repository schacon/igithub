//
//  Git.m
//  ObjGit
//

#import "Git.h"
#import "GitObject.h"
#import "GitCommit.h"
#import "GitServerHandler.h"

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

- (void) writeObject:(NSData *)objectData withType:(int)type withSize:(int)size 
{
	NSLog(@"WRITE OBJECT");
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
	
	return [NSString stringWithFormat: @"%@/objects/%@/%@", \
			gitDirectory, looseSubDir, looseFileName];
}

@end
