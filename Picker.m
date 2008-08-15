/*

*/

#import "Picker.h"

#define kOffset 5.0

@interface Picker ()
@property (nonatomic, retain, readwrite) BrowserViewController* bvc;
@property (nonatomic, retain, readwrite) UILabel* gameNameLabel;
@end

@implementation Picker

@synthesize bvc = _bvc;
@synthesize gameNameLabel = _gameNameLabel;

- (id)initWithFrame:(CGRect)frame type:(NSString*)type {
	if ((self = [super initWithFrame:frame])) {
		self.bvc = [[BrowserViewController alloc] initWithTitle:nil showDisclosureIndicators:NO showCancelButton:NO];
		[self.bvc searchForServicesOfType:type inDomain:@"local"];
		
		self.opaque = YES;
		self.backgroundColor = [UIColor blackColor];
		
		UIImageView* img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg.png"]];
		[self addSubview:img];
		[img release];
		
		CGFloat runningY = kOffset;
		CGFloat width = self.bounds.size.width - 2 * kOffset;
		
		UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
		[label setTextAlignment:UITextAlignmentCenter];
		[label setFont:[UIFont boldSystemFontOfSize:15.0]];
		[label setTextColor:[UIColor whiteColor]];
		[label setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.75]];
		[label setShadowOffset:CGSizeMake(1,1)];
		[label setBackgroundColor:[UIColor clearColor]];
		label.text = @"Git Server At";
		label.numberOfLines = 1;
		[label sizeToFit];
		label.frame = CGRectMake(kOffset, runningY, width, label.frame.size.height);
		[self addSubview:label];
		
		runningY += label.bounds.size.height;
		[label release];
		
		self.gameNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.gameNameLabel setTextAlignment:UITextAlignmentCenter];
		[self.gameNameLabel setFont:[UIFont boldSystemFontOfSize:24.0]];
		[self.gameNameLabel setLineBreakMode:UILineBreakModeTailTruncation];
		[self.gameNameLabel setTextColor:[UIColor whiteColor]];
		[self.gameNameLabel setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.75]];
		[self.gameNameLabel setShadowOffset:CGSizeMake(1,1)];
		[self.gameNameLabel setBackgroundColor:[UIColor clearColor]];
		[self.gameNameLabel setText:@"Default Name"];
		[self.gameNameLabel sizeToFit];
		[self.gameNameLabel setFrame:CGRectMake(kOffset, runningY, width, self.gameNameLabel.frame.size.height)];
		[self.gameNameLabel setText:@""];
		[self addSubview:self.gameNameLabel];
		
		runningY += self.gameNameLabel.bounds.size.height + kOffset * 2;
		
		label = [[UILabel alloc] initWithFrame:CGRectZero];
		[label setTextAlignment:UITextAlignmentCenter];
		[label setFont:[UIFont boldSystemFontOfSize:15.0]];
		[label setTextColor:[UIColor whiteColor]];
		[label setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.75]];
		[label setShadowOffset:CGSizeMake(1,1)];
		[label setBackgroundColor:[UIColor clearColor]];
		label.text = @"git clone";
		label.numberOfLines = 1;
		[label sizeToFit];
		label.frame = CGRectMake(kOffset, runningY, width, label.frame.size.height);
		[self addSubview:label];
		
		runningY += label.bounds.size.height + 2;
		
		[self.bvc.view setFrame:CGRectMake(0, runningY, self.bounds.size.width, self.bounds.size.height - runningY)];
		[self addSubview:self.bvc.view];
		
	}

	return self;
}


- (void)dealloc {
	// Cleanup any running resolve and free memory
	[self.bvc release];
	[self.gameNameLabel release];
	
	[super dealloc];
}


- (id<BrowserViewControllerDelegate>)delegate {
	return self.bvc.delegate;
}


- (void)setDelegate:(id<BrowserViewControllerDelegate>)delegate {
	[self.bvc setDelegate:delegate];
}

- (NSString *)gameName {
	return self.gameNameLabel.text;
}

- (void)setGameName:(NSString *)string {
	[self.gameNameLabel setText:string];
	[self.bvc setOwnName:string];
}

@end
