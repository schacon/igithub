//
//  ProjectController.m
//  iGitHub
//

#import "ProjectController.h"

@interface ProjectController ()
@property (nonatomic, copy, readwrite) NSMutableArray *list;
@end

@implementation ProjectController

@synthesize list;

// Custom set accessor to ensure the new list is mutable
- (void)readProjects:(NSString *)projectPath
{
	NSLog(@"READ PROJECTS:%@", projectPath);
	
	BOOL isDir=NO;
	[list release];
	list = [[NSMutableArray alloc] init];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:projectPath isDirectory:&isDir] && isDir) {
		NSLog(@"paths:%@", [fileManager directoryContentsAtPath:projectPath]);
		NSEnumerator *e = [[fileManager directoryContentsAtPath:projectPath] objectEnumerator];
		NSString *thisDir;
		while ( (thisDir = [e nextObject]) ) {			
			[list addObject:[NSArray arrayWithObjects:thisDir,nil]];
		}
	}
	NSLog(@"LIST:%@", list);
}

// Accessor methods for list
- (unsigned)countOfList {
    return [list count];
}

- (id)objectInListAtIndex:(unsigned)theIndex {
    return [list objectAtIndex:theIndex];
}

- (void)dealloc {
    [list release];
    [super dealloc];
}

@end
