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

@property(copy, readwrite) NSString *sha;	
@property(assign, readwrite) NSInteger size;	
@property(copy, readwrite) NSString *type;	
@property(copy, readwrite) NSString *contents;	
@property(assign, readwrite) char *rawContents;	
@property(assign, readwrite) int rawContentLen;
@property(copy, readwrite) NSData   *raw;	

- (id) initFromRaw:(NSData *)rawData withSha:(NSString *)shaValue;
- (void) parseRaw;
- (NSData *) inflateRaw:(NSData *)rawData;

@end
