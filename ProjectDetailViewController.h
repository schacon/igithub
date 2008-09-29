//
//  ProjectDetailViewController.h
//  iGitHub
//

#import <UIKit/UIkit.h>
#import "ObjGit.h"

@interface ProjectDetailViewController : UITableViewController {
	ObjGit *detailItem;
}

@property (nonatomic, retain) ObjGit *detailItem;

@end
