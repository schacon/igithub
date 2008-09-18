//
//  Git.m
//  ObjGit
//

#import "Git.h"

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

- (BOOL) openRepo:(NSString *)dirPath 
{
	BOOL isDir;
	NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:dirPath isDirectory:&isDir] && isDir) {
		gitDirectory = dirPath;
		return YES;
	}
	return NO;
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
