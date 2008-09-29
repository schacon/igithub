//
//  ProjectViewController.m
//  iGitHub
//

#import "ProjectViewController.h"
#import "ProjectDetailViewController.h"
#import "ObjGit.h"


@implementation ProjectViewController

@synthesize projectController;

- (id)initWithStyle:(UITableViewStyle)style {
	if ((self = [super initWithStyle:style])) {
		self.title = NSLocalizedString(@"Projects", @"My Local Git Project List");
	}
	return self;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [projectController countOfList];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *MyIdentifier = @"MyIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
	}

	// Get the object to display and set the value in the cell
	NSLog(@"TEST 1");
	NSLog(@"OBJ:%@", [projectController objectInListAtIndex:indexPath.row]);
    ObjGit *itemAtIndex = [projectController objectInListAtIndex:indexPath.row];
	NSLog(@"TEST 2");
	NSLog(@"obj:%@", [itemAtIndex getName]);
    cell.text = [itemAtIndex gitName];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ProjectDetailViewController *detailViewController = [[ProjectDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
    detailViewController.detailItem = [projectController objectInListAtIndex:indexPath.row];
    
    // Push the detail view controller
    [[self navigationController] pushViewController:detailViewController animated:YES];
    [detailViewController release];
}

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


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
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

