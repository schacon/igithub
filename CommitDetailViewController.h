//
//  CommitDetailViewController.h
//  iGitHub
//
//  Created by Scott Chacon on 9/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObjGit.h"
#import "ObjGitCommit.h"

@interface CommitDetailViewController : UITableViewController {
	ObjGit *gitRepo;
	ObjGitCommit *gitCommit;
}

@property (nonatomic, retain) ObjGit   *gitRepo;
@property (nonatomic, retain) ObjGitCommit   *gitCommit;

@end
