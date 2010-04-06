/*

File: AppController.m
Abstract: UIApplication's delegate class, the central controller of the
application.

Version: 1.5

*/

#import "AppController.h"
#import "ProjectViewController.h"
#import "ProjectController.h"
#import "ServerViewController.h"
#import "HTTPServer.h"
#import "GitHTTPConnection.h"

#define bonIdentifier @"git"

//INTERFACES:

@interface AppController ()

@property (assign, readwrite) NSString *gitDir;

- (void) setup;

@end

//CLASS IMPLEMENTATIONS:

@implementation AppController

@synthesize gitDir;
@synthesize navigationController;
@synthesize tabBarController;
@synthesize serverViewController;

// creates [userDocs]/git path for git repos
- (NSString *)getGitPath
{
	NSArray *paths;
	NSString *gitPath = @"";
	NSString *tmpPath = @"";
	paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0) {
		gitPath = [NSString stringWithString:[[paths objectAtIndex:0] stringByAppendingPathComponent:@"git"]];
		
		BOOL isDir;
		NSFileManager *fm = [NSFileManager defaultManager];
		if (![fm fileExistsAtPath:gitPath isDirectory:&isDir] && isDir) {
			[fm createDirectoryAtPath:gitPath attributes:nil];
		}

		tmpPath = [NSString stringWithString:[[paths objectAtIndex:0] stringByAppendingPathComponent:@"gitTmp"]];
		
		if (![fm fileExistsAtPath:tmpPath isDirectory:&isDir] && isDir) {
			[fm createDirectoryAtPath:tmpPath attributes:nil];
		}
	}
	return gitPath;
}

- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	NSString * thisHostName = [[NSProcessInfo processInfo] hostName];
	NSLog(@"hostname: %@", thisHostName);
	// Create a full-screen window
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	// getting the git path
	gitDir = [self getGitPath];
		
	// Create and configure the navigation and view controllers
    ProjectController *pController = [[ProjectController alloc] init];
	[pController readProjects:gitDir];
	
    ProjectViewController *projectViewController = [[ProjectViewController alloc] initWithStyle:UITableViewStylePlain];
	[projectViewController setProjectController:pController];

	ServerViewController *serverController = [[ServerViewController alloc] init];
	self.serverViewController = serverController;
	
    UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:projectViewController];
    self.navigationController = aNavigationController;
	
	UITabBarController *atabBarController = [[UITabBarController alloc] init];
	NSArray *vc = [NSArray arrayWithObjects:navigationController, serverViewController, nil];
	[atabBarController setViewControllers:vc animated:NO];
	self.tabBarController = atabBarController;
	
	// start the server	
	httpServer = [HTTPServer new];
	[httpServer setType:@"_http._tcp."];
	[httpServer setConnectionClass:[GitHTTPConnection class]];
	[httpServer setDocumentRoot:[NSURL fileURLWithPath:gitDir]];
	[httpServer setPort:8082];
	
	NSError *error;
	if(![httpServer start:&error])
	{
		NSLog(@"Error starting HTTP Server: %@", error);
	}
	
    // Configure and show the window
	[_window addSubview:tabBarController.view];
    [_window makeKeyAndVisible];

    [projectViewController release];
    [aNavigationController release];
    
	[self setup];
}

- (void) dealloc
{	
	NSLog(@"dealloc");
	[_window release];	
	[super dealloc];
}

- (void) setup {
	// TODO: setup the http server
	NSLog(@"Setup");
	
	gitDir = [self getGitPath];
	
	BOOL isDir=NO;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:gitDir isDirectory:&isDir] && isDir) {
		NSEnumerator *e = [[fileManager directoryContentsAtPath:gitDir] objectEnumerator];
		NSString *thisDir;
		while ( (thisDir = [e nextObject]) ) {
			NSLog(@"announce:%@", thisDir);
			// TODO: announce http over bonjour
		}
	}	
}

@end
