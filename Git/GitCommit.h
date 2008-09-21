//
//  GitCommit.h
//  ObjGit
//

#import <Foundation/Foundation.h>
#import "GitObject.h"

@interface GitCommit : NSObject {
	NSArray	   *parentShas;
	NSString   *treeSha;
	NSString   *author;
	NSString   *author_email;
	NSDate	   *authored_date;
	NSString   *committer;
	NSString   *committer_email;
	NSDate	   *committed_date;
	NSString   *message;
	GitObject  *git_object;
}

@property(assign, readwrite) NSArray   *parentShas;
@property(assign, readwrite) NSString  *treeSha;
@property(assign, readwrite) NSString  *author;	
@property(assign, readwrite) NSString  *author_email;	
@property(assign, readwrite) NSDate	   *authored_date;	
@property(assign, readwrite) NSString  *committer;	
@property(assign, readwrite) NSString  *committer_email;	
@property(assign, readwrite) NSDate	   *committed_date;	
@property(assign, readwrite) NSString  *message;	
@property(assign, readwrite) GitObject *git_object;

- (id) initFromRaw:(NSData *)rawData withSha:(NSString *)shaValue;
- (void) parseContent;
- (void) logObject;
- (NSArray *) parseAuthorString:(NSString *)authorString withType:(NSString *)typeString;

@end
