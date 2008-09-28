//
//  ProjectViewController.h
//  iGitHub
//

#import <UIKit/UIKit.h>
#import "ProjectController.h"

@interface ProjectViewController : UITableViewController {
    ProjectController *projectController;
}

@property (nonatomic, retain) ProjectController *projectController;

@end
