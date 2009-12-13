//
//  ServerViewController.m
//  iGitHub
//


#import "ServerViewController.h"

#define kOffset 5.0

@implementation ServerViewController

@synthesize serverNameLabel;

-(id)init {
	self = [super init];
	if (self) {
		self.title = @"Server";
		self.tabBarItem.image = [UIImage imageNamed:@"rssicon.png"];
	}
	return self;
}

-(void)loadView {
	NSLog(@"First View");
	UIView *firstView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"server.png"]];
	[firstView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
	[firstView setBackgroundColor:[UIColor yellowColor]];
	self.view = firstView;
	[firstView release];
	
	UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
	[label setTextAlignment:UITextAlignmentCenter];
	[label setFont:[UIFont systemFontOfSize:18.0]];
	[label setTextColor:[UIColor blackColor]];
	[label setBackgroundColor:[UIColor clearColor]];
	label.text = @"Git Server Listening On";
	label.numberOfLines = 1;
	[label sizeToFit];
	label.frame = CGRectMake(0.0, 200.0, 320.0, label.frame.size.height);
	[self.view addSubview:label];

	NSString *hostName = [[NSProcessInfo processInfo] hostName];
	if ([hostName hasSuffix:@".local"]) {
		hostName = [hostName substringToIndex:([hostName length] - 6)];
	}
	label = [[UILabel alloc] initWithFrame:CGRectZero];
	[label setTextAlignment:UITextAlignmentCenter];
	[label setFont:[UIFont systemFontOfSize:28.0]];
	[label setTextColor:[UIColor blackColor]];
	[label setBackgroundColor:[UIColor clearColor]];
	label.text = [NSString stringWithFormat:@"git://%@/", hostName];
	label.numberOfLines = 1;
	[label sizeToFit];
	label.frame = CGRectMake(0.0, 250.0, 320.0, label.frame.size.height);
	self.serverNameLabel = label;
	[self.view addSubview:self.serverNameLabel];
}

- (void)setServerName:(NSString *)string {
	[self.serverNameLabel setText:string];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[super dealloc];
}


@end
