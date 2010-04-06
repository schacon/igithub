//
//  CommitDetailViewController.h
//  iGitHub
//
//  Created by Scott Chacon on 9/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Git.h"

@interface CommitDetailViewController : UITableViewController {
	GITRepo	  *gitRepo;
	GITCommit *gitCommit;
}

@property (nonatomic, retain) GITRepo	*gitRepo;
@property (nonatomic, retain) GITCommit *gitCommit;

@end
