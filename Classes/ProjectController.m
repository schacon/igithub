//
//  ProjectController.m
//  iGitHub
//

#import "ProjectController.h"
#import "Git.h"

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
		NSEnumerator *e = [[fileManager directoryContentsAtPath:projectPath] objectEnumerator];
		NSString *thisDir;
		while ( (thisDir = [e nextObject]) ) {
			NSString *dir = [projectPath stringByAppendingPathComponent:thisDir];
			GITRepo* git = [[GITRepo alloc] init];	
			[git initWithRoot:dir];
			[git setDesc:thisDir];
			[list addObject:git];
		}
	}
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
