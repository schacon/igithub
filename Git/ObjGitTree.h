//
//  ObjGitTree.h
//  ObjGit
//

#import <Foundation/Foundation.h>
#import "ObjGitObject.h"

@interface ObjGitTree : NSObject {
	NSArray		  *treeEntries;
	ObjGitObject  *gitObject;
}

@property(assign, readwrite) NSArray   *treeEntries;
@property(assign, readwrite) ObjGitObject *gitObject;

- (id) initFromGitObject:(ObjGitObject *)object;
- (void) parseContent;
- (void) logObject;

@end
