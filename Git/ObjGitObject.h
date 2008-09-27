//
//  ObjGitObject.h
//  ObjGit
//

#import <Foundation/Foundation.h>

@interface ObjGitObject : NSObject {
	NSString* sha;
	NSInteger size;
	NSString* type;
	NSString* contents;
	char* rawContents;
	int rawContentLen;
	NSData*   raw;
}

@property(assign, readwrite) NSString *sha;	
@property(assign, readwrite) NSInteger size;	
@property(assign, readwrite) NSString *type;	
@property(assign, readwrite) NSString *contents;	
@property(assign, readwrite) char *rawContents;	
@property(assign, readwrite) int rawContentLen;
@property(assign, readwrite) NSData   *raw;	

- (id) initFromRaw:(NSData *)rawData withSha:(NSString *)shaValue;
- (void) parseRaw;
- (NSData *) inflateRaw:(NSData *)rawData;

@end
