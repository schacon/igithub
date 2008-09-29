//
//  CommitsViewController.h
//  iGitHub
//

#import <UIKit/UIKit.h>
#import "ObjGit.h"

@interface CommitsViewController : UITableViewController {
	ObjGit   *gitRepo;
	NSString *gitRef;
	NSString *gitSha;
	NSMutableArray *commitList;
}

@property (nonatomic, retain) ObjGit   *gitRepo;
@property (nonatomic, retain) NSString *gitRef;
@property (nonatomic, retain) NSString *gitSha;
@property (nonatomic, retain) NSMutableArray *commitList;

- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier;
- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath;

@end
