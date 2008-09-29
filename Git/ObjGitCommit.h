//
//  ObjGitCommit.h
//  ObjGit
//

#import <Foundation/Foundation.h>
#import "ObjGitObject.h"

@interface ObjGitCommit : NSObject {
	NSString   *sha;
	NSArray	   *parentShas;
	NSString   *treeSha;
	NSString   *author;
	NSString   *author_email;
	NSDate	   *authored_date;
	NSString   *committer;
	NSString   *committer_email;
	NSDate	   *committed_date;
	NSString   *message;
	ObjGitObject  *git_object;
}

@property(copy, readwrite) NSString  *sha;
@property(copy, readwrite) NSArray   *parentShas;
@property(copy, readwrite) NSString    *treeSha;
@property(copy, readwrite) NSString    *author;	
@property(copy, readwrite) NSString    *author_email;	
@property(copy, readwrite) NSDate	   *authored_date;	
@property(copy, readwrite) NSString  *committer;	
@property(copy, readwrite) NSString  *committer_email;	
@property(retain, readwrite) NSDate	   *committed_date;	
@property(assign, readwrite) NSString  *message;	
@property(assign, readwrite) ObjGitObject *git_object;

- (id) initFromGitObject:(ObjGitObject *)gitObject;
- (id) initFromRaw:(NSData *)rawData withSha:(NSString *)shaValue;
- (void) parseContent;
- (void) logObject;
- (NSArray *) authorArray; 
- (NSArray *) parseAuthorString:(NSString *)authorString withType:(NSString *)typeString;

@end
