//
//  GitServerHandler.h
//  ObjGit
//

#import <Foundation/Foundation.h>

@interface GitServerHandler : NSObject {
	NSInputStream*		inStream;
	NSOutputStream*		outStream;
	Git*				gitRepo;
	NSString*			gitPath;

	NSMutableArray*		refsRead;
	int					capabilitiesSent;
}

@property(assign, readwrite) NSInputStream *inStream;	
@property(assign, readwrite) NSOutputStream *outStream;	
@property(assign, readwrite) Git *gitRepo;
@property(assign, readwrite) NSString *gitPath;

@property(assign, readwrite) NSMutableArray *refsRead;
@property(assign, readwrite) int capabilitiesSent;

- (void) initWithGit:(Git *)git gitPath:(NSString *)gitRepoPath input:(NSInputStream *)streamIn output:(NSOutputStream *)streamOut;
- (void) handleRequest;
- (void) receivePack:(NSString *)repositoryName;

- (void) sendRefs;
- (void) sendRef:(NSString *)refName sha:(NSString *)shaString;
- (void) readRefs;
- (void) readPack;
- (void) writeRefs;
- (NSData *) readData:(int)size;

- (int) readPackHeader;
- (void) unpackObject;

- (void) packetFlush;
- (void) writeServer:(NSString *)dataWrite;
- (void) sendPacket:(NSString *)dataSend;
- (NSString *) packetReadLine;

@end
