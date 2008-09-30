//
//  ServerViewController.m
//  iGitHub
//


#import "ServerViewController.h"


@implementation ServerViewController

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
