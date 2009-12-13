//
//  CommitDetailViewController.m
//  iGitHub
//

#import "CommitDetailViewController.h"
#import "ObjGit.h"
#import "ObjGitCommit.h"

@implementation CommitDetailViewController

@synthesize gitRepo;
@synthesize gitCommit;

- (id)initWithStyle:(UITableViewStyle)style {
	if ((self = [super initWithStyle:style])) {
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
    // Update the view with current data before it is displayed
    [super viewWillAppear:animated];
    
    // Scroll the table view to the top before it appears
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointZero animated:NO];
    self.title = [[gitCommit sha] substringToIndex:6];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger rows = 0;
    switch (section) {
        case 0:
            // SHA
            rows = 1;
            break;
        case 1:
            // Author
            rows = 3;
            break;
        case 2:
            // Message
            rows = 1;
            break;
        case 3:
            // Tree
            rows = 1;
            break;
        case 4:
            // Parents
            rows = [[gitCommit parentShas] count];
            break;
        default:
            break;
    }
    return rows;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"commitView";
    
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"MMM dd YY, kk:ss"]; // Sept 5 08:30
	}
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

	CGRect contentRect;
	UILabel *textView;
	struct CGSize size;

    switch (indexPath.section) {
        case 0:
			cell.font = [UIFont fontWithName:@"Courier New" size:12];
			cell.textAlignment = UITextAlignmentCenter;
			cell.text = [self.gitCommit sha];
            break;
        case 1:
			if(indexPath.row == 2) {
				cell.text = [dateFormatter stringFromDate:[[self.gitCommit authorArray] objectAtIndex:indexPath.row]];
			} else {
				cell.text = [[self.gitCommit authorArray] objectAtIndex:indexPath.row];
			}
			break;
		case 2:
			NSLog(@"Message:%@", [self.gitCommit message]);

			size = [[self.gitCommit message] sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(300.0, 4000) lineBreakMode:UILineBreakModeCharacterWrap];

			contentRect = CGRectMake(5.0, 5.0, 290.0, size.height);
			textView = [[UILabel alloc] initWithFrame:contentRect];
			textView.text = [self.gitCommit message];
			textView.numberOfLines = 0;
			textView.lineBreakMode = UILineBreakModeCharacterWrap;
			textView.font = [UIFont systemFontOfSize:14];
			[cell.contentView addSubview:textView];
			[textView release];
			break;
		case 3:
			cell.font = [UIFont fontWithName:@"Courier New" size:12];
			cell.textAlignment = UITextAlignmentCenter;
			cell.text = [self.gitCommit treeSha];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            break;
		case 4:
			cell.font = [UIFont fontWithName:@"Courier New" size:12];
			cell.textAlignment = UITextAlignmentCenter;
			cell.text = [[gitCommit parentShas] objectAtIndex:indexPath.row];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        default:
            break;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    NSString *title = nil;
    switch (section) {
        case 0:
            //title = NSLocalizedString(@"Commit SHA1", @"Commit SHA1 Value");
            break;
        case 1:
            title = NSLocalizedString(@"Author", @"Git Commit Author");
            break;
        case 2:
            title = NSLocalizedString(@"Commit Message", @"Git Commit Message");
            break;
        case 3:
            title = NSLocalizedString(@"Tree", @"Git Commit Tree");
            break;
        case 4:
            title = NSLocalizedString(@"Parents", @"Git Commit Parents");
            break;
        default:
            break;
    }
    return title;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat height = 40.0;
	struct CGSize size;
	switch (indexPath.section) {
        case 0:
			height = 30.0;
			break;
        case 1:
			height = 30.0;
			break;
        case 2:
			size = [[self.gitCommit message] sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(300.0, 4000) lineBreakMode:UILineBreakModeCharacterWrap];
			height = size.height + 10;
			break;
		default:
			break;
	}
	return height;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *sha;
    switch (indexPath.section) {
        case 4: // clicked a parent
			sha = [[gitCommit parentShas] objectAtIndex:indexPath.row];

			CommitDetailViewController *commitViewController = [[CommitDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];	
			commitViewController.gitRepo = self.gitRepo;
			commitViewController.gitCommit = [[ObjGitCommit alloc] initFromGitObject:[gitRepo getObjectFromSha:sha]];
			
			// Push the commit view controller
			[[self navigationController] pushViewController:commitViewController animated:YES];
			[commitViewController release];
			break;
		default:
			break;
	}
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

