/*

File: AppController.m
Abstract: UIApplication's delegate class, the central controller of the
application.

Version: 1.5

*/

#import "ObjGit.h"
#import "ObjGitServerHandler.h"
#import "AppController.h"
#import "ProjectViewController.h"
#import "ProjectController.h"
#import "ServerViewController.h"

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

- (NSString *)getGitPath
{
	NSArray *paths;
	NSString *gitPath = @"";
	paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0) {
		gitPath = [NSString stringWithString:[[paths objectAtIndex:0] stringByAppendingPathComponent:@"git"]];
		
		BOOL isDir;
		NSFileManager *fm = [NSFileManager defaultManager];
		if (![fm fileExistsAtPath:gitPath isDirectory:&isDir] && isDir) {
			[fm createDirectoryAtPath:gitPath attributes:nil];
		}
	}
	return gitPath;
}

- (void) applicationDidFinishLaunching:(UIApplication*)application
{
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
	
    UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:projectViewController];
    self.navigationController = aNavigationController;
	
	UITabBarController *atabBarController = [[UITabBarController alloc] init];
	NSArray *vc = [NSArray arrayWithObjects:navigationController, serverController, nil];
	[atabBarController setViewControllers:vc animated:NO];
	self.tabBarController = atabBarController;
	
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
	[_inStream release];
	[_outStream release];

	[_server release];
	[_window release];
	
	[super dealloc];
}

- (void) setup {
	//[_server release];
	//_server = nil;
	
	[_inStream release];
	_inStream = nil;
	_inReady = NO;

	[_outStream release];
	_outStream = nil;
	_outReady = NO;
	
	_server = [TCPServer new];
	[_server setDelegate:self];
	NSError* error;
	if(_server == nil || ![_server start:&error]) {
		NSLog(@"Failed creating server: %@", error);
		return;
	}
	
	gitDir = [self getGitPath];
	
	BOOL isDir=NO;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:gitDir isDirectory:&isDir] && isDir) {
		NSEnumerator *e = [[fileManager directoryContentsAtPath:gitDir] objectEnumerator];
		NSString *thisDir;
		while ( (thisDir = [e nextObject]) ) {
			NSLog(@"announce:%@", thisDir);
			[_server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:bonIdentifier] name:thisDir];
		}
	}	
}

- (void) openStreams
{
	NSString *tgitDir = [self getGitPath];
	NSLog(@"gitdir:%@", tgitDir);

	[_outStream open];
	[_inStream  open];
	
	ObjGit* git = [ObjGit alloc];
	ObjGitServerHandler *obsh = [[ObjGitServerHandler alloc] init];
	NSLog(@"INIT WITH GIT:  %@ : %@ : %@ : %@ : %@", obsh, git, tgitDir, _inStream, _outStream);
	[obsh initWithGit:git gitPath:tgitDir input:_inStream output:_outStream];				

	[_outStream close];
	[_inStream  close];
	
	[self setup]; // restart the server
}

@end

@implementation AppController (TCPServerDelegate)

- (void) serverDidEnableBonjour:(TCPServer*)server withName:(NSString*)string
{
	//NSLog(@"%s", _cmd);
}

- (void)didAcceptConnectionForServer:(TCPServer*)server inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr
{
	if (_inStream || _outStream || server != _server)
		return;
	
	NSLog(@"accept connection");
	
	[_server stop];
	[_server release];
	_server = nil;
	
	_inStream = istr;
	[_inStream retain];
	_outStream = ostr;
	[_outStream retain];
	
	[self openStreams];
}

@end
