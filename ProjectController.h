//
//  ProjectController.h
//  iGitHub
//

#import <UIKit/UIKit.h>

@interface ProjectController : NSObject {
    NSMutableArray *list;
}

- (void)readProjects:(NSString *)projectPath;
- (unsigned)countOfList;
- (id)objectInListAtIndex:(unsigned)theIndex;

@end
