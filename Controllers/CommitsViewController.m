//
//  CommitsViewController.m
//  iGitHub
//

#import "CommitsViewController.h"
#import "CommitDetailViewController.h"
#import "Git.h"

#define ROW_HEIGHT 60

@implementation CommitsViewController

@synthesize gitRepo;
@synthesize gitRef;
@synthesize gitSha;
@synthesize commitList;

- (id)initWithStyle:(UITableViewStyle)style {
	if ((self = [super initWithStyle:style])) {
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
    // Update the view with current data before it is displayed
    [super viewWillAppear:animated];

	// load data
	NSLog(@"Data load from [%@]", gitSha);
	self.commitList = [gitRepo getCommitsFromCommit:gitSha withLimit:30];
	NSLog(@"Data [%@]", self.commitList);
	
    // Scroll the table view to the top before it appears
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointZero animated:NO];
    self.title = gitRef;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.commitList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *MyIdentifier = @"MyIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) {
		cell = [self tableviewCellWithReuseIdentifier:MyIdentifier];
	}
	// Configure the cell
	
	[self configureCell:cell forIndexPath:indexPath];
	return cell;
}

#define ONE_TAG 1
#define TWO_TAG 2
#define THR_TAG 3
#define FOUR_TAG 4

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    
    /*
	 Cache the formatter. Normally you would use one of the date formatter styles (such as NSDateFormatterShortStyle), but here we want a specific format that excludes seconds.
	 */
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"MMM dd YY, kk:ss"]; // Sept 5 08:30
	}

	GITCommit *commit = [[self.commitList objectAtIndex:indexPath.row] object];
	
	UILabel *label;
	
	// Get the time zone wrapper for the row
	label = (UILabel *)[cell viewWithTag:ONE_TAG];
	label.text = [[commit sha1] substringToIndex:6];
	
	label = (UILabel *)[cell viewWithTag:TWO_TAG];
	label.text = [[commit author] name];
	
	label = (UILabel *)[cell viewWithTag:THR_TAG];
	label.text = [dateFormatter stringFromDate:[[commit authored] date]];
	
	label = (UILabel *)[cell viewWithTag:FOUR_TAG];
	label.text = [commit message];
}    


- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier {
	
	/*
	 Create an instance of UITableViewCell and add tagged subviews for the name, local time, and quarter image of the time zone.
	 */
	CGRect rect;
	
	rect = CGRectMake(0.0, 0.0, 320.0, ROW_HEIGHT);
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:rect reuseIdentifier:identifier] autorelease];
	
#define LEFT_COLUMN_OFFSET 10.0
#define LEFT_COLUMN_WIDTH 70.0
	
#define MIDDLE_COLUMN_OFFSET 80.0
#define MIDDLE_COLUMN_WIDTH 130.0
	
#define RIGHT_COLUMN_OFFSET 210.0
#define RIGHT_COLUMN_WIDTH 90.0
	
#define MAIN_FONT_SIZE 18.0
#define LABEL_HEIGHT 26.0
		
	/*
	 Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
	 */
	UILabel *label;
	
	rect = CGRectMake(LEFT_COLUMN_OFFSET, 10, LEFT_COLUMN_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = ONE_TAG;
	label.font = [UIFont fontWithName:@"Courier New" size:15];
	label.adjustsFontSizeToFitWidth = YES;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	[label release];
	
	rect = CGRectMake(MIDDLE_COLUMN_OFFSET, 0, MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = TWO_TAG;
	label.font = [UIFont systemFontOfSize:15];
	label.textAlignment = UITextAlignmentLeft;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	[label release];
	
	rect = CGRectMake(RIGHT_COLUMN_OFFSET, 0, RIGHT_COLUMN_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = THR_TAG;
	label.textAlignment = UITextAlignmentRight;
	label.font = [UIFont systemFontOfSize:10];
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	[label release];
	
	rect = CGRectMake(MIDDLE_COLUMN_OFFSET, LABEL_HEIGHT, 200.0, 15);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = FOUR_TAG;
	label.textAlignment = UITextAlignmentLeft;
	label.font = [UIFont systemFontOfSize:10];
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	[label release];
	
	return cell;
}

// SWITCH TO SINGLE COMMIT VIEW //

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CommitDetailViewController *commitViewController = [[CommitDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];	
    commitViewController.gitRepo = self.gitRepo;
    commitViewController.gitCommit = [[self.commitList objectAtIndex:indexPath.row] object];

    // Push the commit view controller
    [[self navigationController] pushViewController:commitViewController animated:YES];
    [commitViewController release];
}

/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}
*/
/*
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (editingStyle == UITableViewCellEditingStyleDelete) {
	}
	if (editingStyle == UITableViewCellEditingStyleInsert) {
	}
}
*/
/*
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/
/*
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/
/*
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/


- (void)dealloc {
	[super dealloc];
}


- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}


@end

