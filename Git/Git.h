//
//  Git.h
//  ObjGit
//

//#import <UIKit/UIKit.h>
//#import <Foundation/NSNetServices.h>
//#include <CFNetwork/CFSocketStream.h>

#import <Foundation/Foundation.h>
#import "GitObject.h"

@interface Git : NSObject {
	NSString* gitDirectory;
}

@property(assign, readwrite) NSString *gitDirectory;

- (BOOL) openRepo:(NSString *)dirPath;
- (BOOL) ensureGitPath;
- (void) initGitRepo;

- (NSString *) writeObject:(NSData *)objectData withType:(NSString *)type withSize:(int)size;

- (NSMutableArray *) getCommitsFromSha:(NSString *)shaValue withLimit:(int)commitSize;
- (NSString *) getLooseObjectPathBySha:(NSString *)shaValue;
- (BOOL) hasObject: (NSString *)sha1;
- (GitObject *) getObjectFromSha:(NSString *)sha1;

+ (int) isAlpha:(unsigned char)n ;
+ (int) gitUnpackHex:(const unsigned char *)rawsha fillSha:(char *)sha1;
+ (int) gitPackHex:(const char *)sha1 fillRawSha:(unsigned char *)rawsha;

@end