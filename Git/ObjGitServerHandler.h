//
//  ObjGitServerHandler.h
//  ObjGit
//

#import <Foundation/Foundation.h>
#include <CommonCrypto/CommonDigest.h>
#import "ObjGitObject.h"

@interface ObjGitServerHandler : NSObject {
	NSInputStream*		inStream;
	NSOutputStream*		outStream;
	ObjGit*				gitRepo;
	NSString*			gitPath;

	NSMutableArray*			refsRead;
	NSMutableArray*			needRefs;
	NSMutableDictionary*	refDict;
	
	int					capabilitiesSent;
}

@property(assign, readwrite) NSInputStream *inStream;	
@property(assign, readwrite) NSOutputStream *outStream;	
@property(assign, readwrite) ObjGit *gitRepo;
@property(assign, readwrite) NSString *gitPath;

@property(assign, readwrite) NSMutableArray *refsRead;
@property(assign, readwrite) NSMutableArray *needRefs;
@property(assign, readwrite) NSMutableDictionary *refDict;

@property(assign, readwrite) int capabilitiesSent;

- (void) initWithGit:(ObjGit *)git gitPath:(NSString *)gitRepoPath input:(NSInputStream *)streamIn output:(NSOutputStream *)streamOut;
- (void) handleRequest;

- (void) uploadPack:(NSString *)repositoryName;
- (void) receiveNeeds;
- (void) uploadPackFile;
- (void) sendNack;
- (void) sendPackData;

- (void) receivePack:(NSString *)repositoryName;
- (void) gatherObjectShasFromCommit:(NSString *)shaValue;
- (void) gatherObjectShasFromTree:(NSString *)shaValue;
- (void) respondPack:(uint8_t *)buffer length:(int)size checkSum:(CC_SHA1_CTX *)checksum;

- (void) sendRefs;
- (void) sendRef:(NSString *)refName sha:(NSString *)shaString;
- (void) readRefs;
- (void) readPack;
- (void) writeRefs;
- (NSData *) readData:(int)size;
- (NSString *) typeString:(int)type;
- (int) typeInt:(NSString *)type;
- (void) unpackDeltified:(int)type size:(int)size;

- (NSData *) patchDelta:(NSData *)deltaData withObject:(ObjGitObject *)gitObject;
- (NSArray *) patchDeltaHeaderSize:(NSData *)deltaData position:(int)position;

- (NSString *)readServerSha;
- (int) readPackHeader;
- (void) unpackObject;

- (void) longVal:(uint32_t)raw toByteBuffer:(uint8_t *)buffer;
- (void) packetFlush;
- (void) writeServer:(NSString *)dataWrite;
- (void) writeServerLength:(unsigned int)length;
- (void) sendPacket:(NSString *)dataSend;
- (NSString *) packetReadLine;

@end
