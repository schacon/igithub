//
//  ObjGit.h
//  ObjGit
//

//#import <UIKit/UIKit.h>
//#import <Foundation/NSNetServices.h>
//#include <CFNetwork/CFSocketStream.h>

#import <Foundation/Foundation.h>
#import "ObjGitObject.h"

@interface ObjGit : NSObject {
	NSString* gitDirectory;
	NSString* gitName;
}

@property(copy, readwrite) NSString *gitDirectory;
@property(copy, readwrite) NSString *gitName;

- (BOOL) openRepo:(NSString *)dirPath;
- (BOOL) ensureGitPath;
- (void) initGitRepo;
- (NSArray *) getAllRefs;

- (NSString *) writeObject:(NSData *)objectData withType:(NSString *)type withSize:(int)size;
- (void) updateRef:(NSString *)refName toSha:(NSString *)toSha;

- (NSMutableArray *) getCommitsFromSha:(NSString *)shaValue withLimit:(int)commitSize;
- (NSString *) getLooseObjectPathBySha:(NSString *)shaValue;
- (BOOL) hasObject: (NSString *)sha1;
- (ObjGitObject *) getObjectFromSha:(NSString *)sha1;

+ (int) isAlpha:(unsigned char)n ;
+ (int) gitUnpackHex:(const unsigned char *)rawsha fillSha:(char *)sha1;
+ (int) gitPackHex:(const char *)sha1 fillRawSha:(unsigned char *)rawsha;

@end