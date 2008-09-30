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

#define bonIdentifier		@"github"

//INTERFACES:

@interface AppController ()

@property (assign, readwrite) NSString *gitDir;

- (void) setup;

@end

//CLASS IMPLEMENTATIONS:

@implementation AppController

@synthesize gitDir;
@synthesize navigationController;

- (void) _showAlert:(NSString*)title
{
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:@"Check your networking configuration." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

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
	//Create a full-screen window
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	// getting the git path
	gitDir = [self getGitPath];
		
	// Create and configure the navigation and view controllers
    ProjectController *pController = [[ProjectController alloc] init];
	[pController readProjects:gitDir];
	
    ProjectViewController *projectViewController = [[ProjectViewController alloc] initWithStyle:UITableViewStylePlain];
	[projectViewController setProjectController:pController];
	
    UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:projectViewController];
    self.navigationController = aNavigationController;
    [aNavigationController release];
    [projectViewController release];
    
    // Configure and show the window
    [_window addSubview:[navigationController view]];
    [_window makeKeyAndVisible];

	//Create and advertise a new game and discover other availble games
	[self setup];
}

- (void) dealloc
{	
	NSLog(@"dealloc");
	[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[_inStream release];

	[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[_outStream release];

	[_server release];
	[_window release];
	
	[super dealloc];
}

- (void) setup {
	[_server release];
	_server = nil;
	
	[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inStream release];
	_inStream = nil;
	_inReady = NO;

	[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outStream release];
	_outStream = nil;
	_outReady = NO;
	
	_server = [TCPServer new];
	[_server setDelegate:self];
	NSError* error;
	if(_server == nil || ![_server start:&error]) {
		NSLog(@"Failed creating server: %@", error);
		[self _showAlert:@"Failed creating server"];
		return;
	}
	
	//Start advertising to clients, passing nil for the name to tell Bonjour to pick use default name
	if(![_server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:bonIdentifier] name:nil]) {
		[self _showAlert:@"Failed advertising server"];
		return;
	}
	

}

- (void) send:(const uint8_t)message
{
	if (_outStream && [_outStream hasSpaceAvailable])
		if([_outStream write:(const uint8_t *)&message maxLength:sizeof(const uint8_t)] == -1)
			[self _showAlert:@"Failed sending data to peer"];
}

- (void) openStreams
{
	_inStream.delegate = self;
	[_inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inStream open];
	_outStream.delegate = self;
	[_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outStream open];
}

- (void) browserViewController:(BrowserViewController*)bvc didResolveInstance:(NSNetService*)netService
{
	if (!netService) {
		[self setup];
		return;
	}

	if (![netService getInputStream:&_inStream outputStream:&_outStream]) {
		[self _showAlert:@"Failed connecting to server"];
		return;
	}

	[self openStreams];
}

@end

@implementation AppController (NSStreamDelegate)

- (void) stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode
{
	switch(eventCode) {
		case NSStreamEventOpenCompleted:
		{			
			if (stream == _inStream)
				_inReady = YES;
			else
				_outReady = YES;
			
			NSLog(@"%s", _cmd);

			NSString *tgitDir = [self getGitPath];
			NSLog(@"gitdir:%@", tgitDir);
			
			//NSLog(@"out avail:%d", [_outStream hasSpaceAvailable]);
			//NSLog(@" in avail:%d", [_inStream  hasBytesAvailable]);

			if (_inReady && _outReady) {
				ObjGit* git = [ObjGit alloc];
				ObjGitServerHandler *obsh = [ObjGitServerHandler alloc];
				NSLog(@"INIT WITH GIT:  %@ : %@ : %@ : %@", git, obsh, _inStream, _outStream);
				[obsh initWithGit:git gitPath:tgitDir input:_inStream output:_outStream];				
				NSLog(@"INIT WITH GIT");
				[self setup]; // restart the server
			}

			break;
		}
		case NSStreamEventHasBytesAvailable:
		{
			break;
		}
		case NSStreamEventEndEncountered:
		{
			break;
		}
	}
}

@end

@implementation AppController (TCPServerDelegate)

- (void) serverDidEnableBonjour:(TCPServer*)server withName:(NSString*)string
{
	NSLog(@"testtest");
	NSLog(@"%s", _cmd);
}

- (void)didAcceptConnectionForServer:(TCPServer*)server inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr
{
	if (_inStream || _outStream || server != _server)
		return;
	
	NSLog(@"accept connection");
	
	[_server release];
	_server = nil;
	
	_inStream = istr;
	[_inStream retain];
	_outStream = ostr;
	[_outStream retain];
	
	[self openStreams];
}

@end
