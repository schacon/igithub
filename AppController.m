/*

File: AppController.m
Abstract: UIApplication's delegate class, the central controller of the
application.

Version: 1.5

*/

#import "Git.h"
#import "GitServerHandler.h"
#import "AppController.h"
#import "Picker.h"

//CONSTANTS:

#define kNumPads			3

// The Bonjour application protocol, which must:
// 1) be no longer than 14 characters
// 2) contain only lower-case letters, digits, and hyphens
// 3) begin and end with lower-case letter or digit
// It should also be descriptive and human-readable
// See the following for more information:
// http://developer.apple.com/networking/bonjour/faq.html
#define kGameIdentifier		@"github"


//INTERFACES:

@interface AppController ()
- (void) setup;
- (void) presentPicker:(NSString*)name;
@end

//CLASS IMPLEMENTATIONS:

@implementation AppController

@synthesize gitDir;

- (void) _showAlert:(NSString*)title
{
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:@"Check your networking configuration." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	CGRect					rect;
	UIView*					view;
	NSUInteger				x,
							y;
	
	//Create a full-screen window
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[_window setBackgroundColor:[UIColor darkGrayColor]];
	
	//Create the tap views and add them to the view controller's view
	rect = [[UIScreen mainScreen] applicationFrame];
	for(y = 0; y < kNumPads; ++y) {
		for(x = 0; x < kNumPads; ++x) {
			view = [[TapView alloc] initWithFrame:CGRectMake(rect.origin.x + x * rect.size.width / (float)kNumPads, rect.origin.y + y * rect.size.height / (float)kNumPads, rect.size.width / (float)kNumPads, rect.size.height / (float)kNumPads)];
			[view setMultipleTouchEnabled:NO];
			[view setBackgroundColor:[UIColor colorWithHue:((y * kNumPads + x) / (float)(kNumPads * kNumPads)) saturation:0.75 brightness:0.75 alpha:1.0]];
			[view setTag:(y * kNumPads + x + 1)];
			[_window addSubview:view];
			[view release];
		}
	}
	
	//Show the window
	[_window makeKeyAndVisible];
	
	//Create and advertise a new game and discover other availble games
	[self setup];
}

- (void) dealloc
{	
	[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[_inStream release];

	[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[_outStream release];

	[_server release];
	[_picker release];
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
	if(![_server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier] name:nil]) {
		[self _showAlert:@"Failed advertising server"];
		return;
	}

	[self presentPicker:nil];
}

// Make sure to let the user know what name is being used for Bonjour advertisement.
// This way, other players can browse for and connect to this game.
// Note that this may be called while the alert is already being displayed, as
// Bonjour may detect a name conflict and rename dynamically.
- (void) presentPicker:(NSString*)name {
	if (!_picker) {
		_picker = [[Picker alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] type:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier]];
		_picker.delegate = self;
	}
	
	_picker.gameName = name;

	if (!_picker.superview) {
		[_window addSubview:_picker];
	}
}

- (void) destroyPicker {
	[_picker removeFromSuperview];
	[_picker release];
	_picker = nil;
}

// If we display an error or an alert that the remote disconnected, handle dismissal and return to setup
- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[self setup];
}

- (void) send:(const uint8_t)message
{
	if (_outStream && [_outStream hasSpaceAvailable])
		if([_outStream write:(const uint8_t *)&message maxLength:sizeof(const uint8_t)] == -1)
			[self _showAlert:@"Failed sending data to peer"];
}

- (void) activateView:(TapView*)view
{
	[self send:[view tag] | 0x80];
}

- (void) deactivateView:(TapView*)view
{
	[self send:[view tag] & 0x7f];
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
	UIAlertView* alertView;
	switch(eventCode) {
		case NSStreamEventOpenCompleted:
		{
			[self destroyPicker];
			
			[_server release];
			_server = nil;

			if (stream == _inStream)
				_inReady = YES;
			else
				_outReady = YES;
			
			NSLog(@"%s", _cmd);

			if (_inReady && _outReady) {
				alertView = [[UIAlertView alloc] initWithTitle:@"Git server started!" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
				[alertView show];
				[alertView release];
								
				// getting the git path
				NSArray *paths;
				paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
				if ([paths count] > 0) {
					gitDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"git"];
					
					BOOL isDir;
					NSFileManager *fm = [NSFileManager defaultManager];
					if (![fm fileExistsAtPath:gitDir isDirectory:&isDir] && isDir) {
						[fm createDirectoryAtPath:gitDir attributes:nil];
					}
				}
				
				Git* git = [Git alloc];
				[[GitServerHandler alloc] initWithGit:git gitPath:gitDir input:_inStream output:_outStream];				
			}

			break;
		}
		case NSStreamEventHasBytesAvailable:
		{
			break;
		}
		case NSStreamEventEndEncountered:
		{
			NSArray*				array = [_window subviews];
			TapView*				view;
			
			NSLog(@"%s", _cmd);
			
			//Notify all tap views
			for(view in array)
				[view touchUp:YES];

			break;
		}
	}
}

@end

@implementation AppController (TCPServerDelegate)

- (void) serverDidEnableBonjour:(TCPServer*)server withName:(NSString*)string
{
	NSLog(@"%s", _cmd);
	[self presentPicker:string];
}

- (void)didAcceptConnectionForServer:(TCPServer*)server inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr
{
	if (_inStream || _outStream || server != _server)
		return;
	
	[_server release];
	_server = nil;
	
	_inStream = istr;
	[_inStream retain];
	_outStream = ostr;
	[_outStream retain];
	
	[self openStreams];
}

@end
