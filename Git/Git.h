//
//  Git.h
//  ObjGit
//

//#import <UIKit/UIKit.h>
//#import <Foundation/NSNetServices.h>
//#include <CFNetwork/CFSocketStream.h>

#import <Foundation/Foundation.h>

@interface Git : NSObject {
	NSString* gitDirectory;
}

@property(assign, readwrite) NSString *gitDirectory;

- (BOOL) openRepo:(NSString *)dirPath;
- (BOOL) ensureGitPath;
- (void) initGitRepo;

- (void) writeObject:(NSData *)objectData withType:(int)type withSize:(int)size;

- (NSMutableArray *) getCommitsFromSha:(NSString *)shaValue withLimit:(int)commitSize;
- (NSString *) getLooseObjectPathBySha:(NSString *)shaValue;

@end
