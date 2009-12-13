//
//  ProjectDetailViewController.h
//  iGitHub
//

#import <UIKit/UIkit.h>
#import "Git.h"

@interface ProjectDetailViewController : UITableViewController {
	GITRepo *detailItem;
}

@property (nonatomic, retain) GITRepo *detailItem;

@end
