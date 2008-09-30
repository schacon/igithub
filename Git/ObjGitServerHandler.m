//
//  ObjGitServerHandler.m
//  ObjGit
//

#define NULL_SHA @"0000000000000000000000000000000000000000"
#define CAPABILITIES @" report-status delete-refs "

#define PACK_SIGNATURE 0x5041434b	/* "PACK" */
#define PACK_VERSION 2

#define OBJ_NONE	0
#define OBJ_COMMIT	1
#define OBJ_TREE	2
#define OBJ_BLOB	3
#define OBJ_TAG		4
#define OBJ_OFS_DELTA 6
#define OBJ_REF_DELTA 7

#import "ObjGit.h"
#import "ObjGitObject.h"
#import "ObjGitCommit.h"
#import "ObjGitTree.h"
#import "ObjGitServerHandler.h"
#import "NSDataCompression.h"
#include <zlib.h>
#include <CommonCrypto/CommonDigest.h>

@implementation ObjGitServerHandler

@synthesize inStream;
@synthesize outStream;
@synthesize gitRepo;
@synthesize gitPath;

@synthesize refsRead;
@synthesize needRefs;
@synthesize refDict;

@synthesize capabilitiesSent;

- (void) initWithGit:(ObjGit *)git gitPath:(NSString *)gitRepoPath input:(NSInputStream *)streamIn output:(NSOutputStream *)streamOut
{
	gitRepo		= git;
	gitPath 	= gitRepoPath;
	inStream	= streamIn;
	outStream	= streamOut;
	[self handleRequest];
}

/* 
 * initiates communication with an incoming request
 * and passes it to the appropriate receiving function
 * either upload-pack for fetches or receive-pack for pushes
 */
- (void) handleRequest {
	NSLog(@"HANDLE REQUEST");
	NSString *header, *command, *repository, *repo, *hostpath;
	header = [self packetReadLine];
	
	NSArray *values = [header componentsSeparatedByString:@" "];
	command		= [values objectAtIndex: 0];			
	repository	= [values objectAtIndex: 1];
	
	values = [repository componentsSeparatedByCharactersInSet:[NSCharacterSet controlCharacterSet]];
	repo		= [values objectAtIndex: 0];			
	hostpath	= [values objectAtIndex: 1];
	
	NSLog(@"header: %@ : %@ : %@", command, repo, hostpath);

	NSString *dir = [gitPath stringByAppendingPathComponent:repo];
	[gitRepo openRepo:dir];
	
	if([command isEqualToString: @"git-receive-pack"]) {		// git push  //
		[self receivePack:repository];
	} else if ([command isEqualToString: @"git-upload-pack"]) {	// git fetch //
		[self uploadPack:repository];
	}

}

/*** UPLOAD-PACK FUNCTIONS ***/

- (void) uploadPack:(NSString *)repositoryName {
	[self sendRefs];
	[self receiveNeeds];
	[self uploadPackFile];
	//NSLog(@"out:%@", outStream);	
	//NSLog(@"out avail:%d", [outStream hasSpaceAvailable]);
	//NSLog(@" in avail:%d", [inStream  hasBytesAvailable]);
}

- (void) receiveNeeds
{
	NSLog(@"receive needs");
	NSString *data, *cmd, *sha;
	NSArray *values;
	needRefs = [[NSMutableArray alloc] init];

	while(![(data = [self packetReadLine]) isEqualToString:@"done\n"]) {
		if([data length] > 40) {
			NSLog(@"data line: %@", data);
			
			values = [data componentsSeparatedByString:@" "];
			cmd	= [values objectAtIndex: 0];			
			sha	= [values objectAtIndex: 1];
			
			[needRefs addObject:values];
		}
	}
	
	//puts @session.recv(9)
	NSLog(@"need refs:%@", needRefs);
	NSLog(@"sending nack");
	[self sendNack];
}

- (void) uploadPackFile
{
	NSLog(@"upload pack file");
	NSString *command, *shaValue;
	NSArray *thisRef;

	refDict = [[NSMutableDictionary alloc] init];
	
	NSEnumerator *e    = [needRefs objectEnumerator];
	while ( (thisRef = [e nextObject]) ) {
		command  = [thisRef objectAtIndex:0];
		shaValue = [thisRef objectAtIndex:1];
		if([command isEqualToString:@"have"]) {
			[refDict setObject:@"have" forKey:shaValue];
		}
	}

	NSLog(@"gathering shas");
	e    = [needRefs objectEnumerator];
	while ( (thisRef = [e nextObject]) ) {
		command  = [thisRef objectAtIndex:0];
		shaValue = [thisRef objectAtIndex:1];
		if([command isEqualToString:@"want"]) {
			[self gatherObjectShasFromCommit:shaValue];
		}
	}
	
	[self sendPackData];
}

- (void) sendPackData
{
	NSLog(@"send pack data");
	NSString *current;
	NSEnumerator *e;
	
	CC_SHA1_CTX *checksum;
	CC_SHA1_Init(checksum);
	
	//NSArray *shas;
	//shas = [refDict keysSortedByValueUsingSelector:@selector(compare:)];
	
	uint8_t buffer[5];	
	
	// write pack header
	
	[self longVal:htonl(PACK_SIGNATURE) toByteBuffer:buffer];
	[self respondPack:buffer length:4 checkSum:checksum];

	[self longVal:htonl(PACK_VERSION) toByteBuffer:buffer];
	[self respondPack:buffer length:4 checkSum:checksum];

	[self longVal:htonl([refDict count]) toByteBuffer:buffer];
	NSLog(@"write len [%d %d %d %d]", buffer[0], buffer[1], buffer[2], buffer[3]);
	[self respondPack:buffer length:4 checkSum:checksum];
	
	//NSLog(@"refs: %@", shas);
	e    = [refDict keyEnumerator];
	ObjGitObject *obj;
	NSData *objData, *data;
	int size, btype, c;
	while ( (current = [e nextObject]) ) {
		obj = [gitRepo getObjectFromSha:current];
		size = [obj size];
		btype = [self typeInt:[obj type]];
		
		c = (btype << 4) | (size & 15);
		size = (size >> 4);
		if(size > 0) 
			c |= 0x80;
		buffer[0] = c;
		[self respondPack:buffer length:1 checkSum:checksum];
		
		while (size > 0) {
			c = size & 0x7f;
			size = (size >> 7);
			if(size > 0)
				c |= 0x80;
			buffer[0] = c;
			[self respondPack:buffer length:1 checkSum:checksum];
		}
		 
		// pack object data
		//NSLog(@"srclen:%d, %d", [obj size], [obj rawContentLen]);
		objData = [NSData dataWithBytes:[obj rawContents] length:([obj rawContentLen])];
		data = [objData compressedData];

		int len = [data length];
		uint8_t dataBuffer[len + 1];
		[data getBytes:dataBuffer];
		
		[self respondPack:dataBuffer length:len checkSum:checksum];
	}

	unsigned char finalSha[20];
	CC_SHA1_Final(finalSha, checksum);
	
	[outStream write:finalSha maxLength:20];
	NSLog(@"end sent");	 
}

- (void) respondPack:(uint8_t *)buffer length:(int)size checkSum:(CC_SHA1_CTX *)checksum 
{
	CC_SHA1_Update(checksum, buffer, size);
	[outStream write:buffer maxLength:size];
}

- (void) longVal:(uint32_t)raw toByteBuffer:(uint8_t *)buffer
{
	buffer[3] = (raw >> 24);
	buffer[2] = (raw >> 16);
	buffer[1] = (raw >> 8);
	buffer[0] = (raw);
}

- (void) gatherObjectShasFromCommit:(NSString *)shaValue 
{
	NSString *parentSha;
	ObjGitCommit *commit = [[ObjGitCommit alloc] initFromGitObject:[gitRepo getObjectFromSha:shaValue]];
	[refDict setObject:@"_commit" forKey:shaValue];

	// add the tree objects
	[self gatherObjectShasFromTree:[commit treeSha]];

	NSArray *parents = [commit parentShas];
	
	NSEnumerator *e = [parents objectEnumerator];
	while ( (parentSha = [e nextObject]) ) {
		NSLog(@"parent sha:%@", parentSha);
		// TODO : check that refDict does not have this
		[self gatherObjectShasFromCommit:parentSha];
	}
}

- (void) gatherObjectShasFromTree:(NSString *)shaValue 
{
	ObjGitTree *tree = [ObjGitTree alloc];
	[tree initFromGitObject:[gitRepo getObjectFromSha:shaValue]];
	[refDict setObject:@"/" forKey:shaValue];
	NSEnumerator *e = [[tree treeEntries] objectEnumerator];
	//[tree release];
	NSArray *entries;
	NSString *name, *sha, *mode;
	while ( (entries = [e nextObject]) ) {
		mode = [entries objectAtIndex:0];
		name = [entries objectAtIndex:1];
		sha  = [entries objectAtIndex:2];
		[refDict setObject:name forKey:sha];
		if ([mode isEqualToString:@"40000"]) { // tree
			// TODO : check that refDict does not have this
			[self gatherObjectShasFromTree:sha];
		}
	}
}


- (void) sendNack
{
	[self sendPacket:@"0007NAK"];
}


/*** UPLOAD-PACK FUNCTIONS END ***/



/*** RECEIVE-PACK FUNCTIONS ***/

/*
 * handles a push request - this involves validating the request,
 * initializing the repository if it's not there, sending the
 * refs we have, receiving the packfile form the client and unpacking
 * the packed objects (eventually we should have an option to keep the
 * packfile and build an index instead)
 */
- (void) receivePack:(NSString *)repositoryName {
	capabilitiesSent = 0;
	
	[gitRepo ensureGitPath];
	
	[self sendRefs];
	[self readRefs];
	[self readPack];
	[self writeRefs];
	[self packetFlush];
}

- (void) sendRefs {
	NSLog(@"send refs");

	NSArray *refs = [gitRepo getAllRefs];
	NSLog(@"refs: %@", refs);
	
	NSEnumerator *e = [refs objectEnumerator];
	NSString *refName, *shaValue;
	NSArray *thisRef;
	while ( (thisRef = [e nextObject]) ) {
		refName  = [thisRef objectAtIndex:0];
		shaValue = [thisRef objectAtIndex:1];
		[self sendRef:refName sha:shaValue];
	}

	// send capabilities and null sha to client if no refs //
	if(!capabilitiesSent)
		[self sendRef:@"capabilities^{}" sha:NULL_SHA];
	[self packetFlush];
}

- (void) sendRef:(NSString *)refName sha:(NSString *)shaString {
	NSString *sendData;
	if(capabilitiesSent) 
		sendData = [[NSString alloc] initWithFormat:@"%@ %@\n", shaString, refName];
	else
		sendData = [[NSString alloc] initWithFormat:@"%@ %@\0%@\n", shaString, refName, CAPABILITIES];
	[self writeServer:sendData];
	capabilitiesSent = 1;
}

- (void) readRefs {
	NSString *data, *old, *new, *refName, *cap, *refStuff;
	NSLog(@"read refs");
	data = [self packetReadLine];
	NSMutableArray *refs = [[NSMutableArray alloc] init];
	while([data length] > 0) {
		
		NSArray  *values  = [data componentsSeparatedByString:@" "];
		old = [values objectAtIndex:0];
		new = [values objectAtIndex:1];
		refStuff = [values objectAtIndex:2];
		
		NSArray  *ref  = [refStuff componentsSeparatedByString:@"\0"];
		refName = [ref objectAtIndex:0];
		cap = nil;
		if([ref count] > 1) 
			cap = [ref objectAtIndex:1];

		NSArray *refData = [NSArray arrayWithObjects:old, new, refName, cap, nil];
		[refs addObject:refData];  // save the refs for writing later
		
		/* DEBUGGING */
		NSLog(@"ref: [%@ : %@ : %@]", old, new, refName, cap);
		
		data = [self packetReadLine];
	}
	refsRead = [NSArray arrayWithArray:refs];
}

/*
 * read packfile data from the stream and expand the objects out to disk
 */
- (void) readPack {
	NSLog(@"read pack");
	int n;
	int entries = [self readPackHeader];
	
	for(n = 1; n <= entries; n++) {
		NSLog(@"entry: %d", n);
		[self unpackObject];
	}
	
	// receive and process checksum
	uint8_t checksum[20];
	[inStream read:checksum maxLength:20];
} 

- (void) unpackObject {	
	// read in the header
	int size, type, shift;
	uint8_t byte[1];
	[inStream read:byte maxLength:1];
	
	size = byte[0] & 0xf;
	type = (byte[0] >> 4) & 7;
	shift = 4;
	while((byte[0] & 0x80) != 0) {
		[inStream read:byte maxLength:1];
        size |= ((byte[0] & 0x7f) << shift);
        shift += 7;
	}
	
	NSLog(@"TYPE: %d", type);
	NSLog(@"size: %d", size);
	
	if((type == OBJ_COMMIT) || (type == OBJ_TREE) || (type == OBJ_BLOB) || (type == OBJ_TAG)) {
		NSData *objectData;
		objectData = [self readData:size];
		[gitRepo writeObject:objectData withType:[self typeString:type] withSize:size];
		// TODO : check saved delta objects
	} else if ((type == OBJ_REF_DELTA) || (type == OBJ_OFS_DELTA)) {
		[self unpackDeltified:type size:size];
	} else {
		NSLog(@"bad object type %d", type);
	}
}

- (void) unpackDeltified:(int)type size:(int)size {
	if(type == OBJ_REF_DELTA) {
		NSString *sha1;
		NSData *objectData, *contents;

		sha1 = [self readServerSha];
		//NSLog(@"DELTA SHA: %@", sha1);
		objectData = [self readData:size];

		if([gitRepo hasObject:sha1]) {
			ObjGitObject *object;
			object = [gitRepo getObjectFromSha:sha1];
			contents = [self patchDelta:objectData withObject:object];
			//NSLog(@"unpacked delta: %@ : %@", contents, [object type]);
			[gitRepo writeObject:contents withType:[object type] withSize:[contents length]];
			//[object release];
		} else {
			// TODO : OBJECT ISN'T HERE YET, SAVE THIS DELTA FOR LATER //
			/*
			 @delta_list[sha1] ||= []
			 @delta_list[sha1] << delta
			 */
		}
	} else {
		// offset deltas not supported yet
		// this isn't returned in the capabilities, so it shouldn't be a problem
	}
}

- (NSData *) patchDelta:(NSData *)deltaData withObject:(ObjGitObject *)gitObject
{
	unsigned long sourceSize, destSize, position;
	unsigned long cp_off, cp_size;
	unsigned char c[2], d[2];
	
	int buffLength = 1000;
	NSMutableData *buffer = [[NSMutableData alloc] initWithCapacity:buffLength];
	
	NSArray *sizePos = [self patchDeltaHeaderSize:deltaData position:0];
	sourceSize	= [[sizePos objectAtIndex:0] longValue];
	position	= [[sizePos objectAtIndex:1] longValue];
	
	//NSLog(@"SS: %d  Pos:%d", sourceSize, position);

	sizePos = [self patchDeltaHeaderSize:deltaData position:position];
	destSize	= [[sizePos objectAtIndex:0] longValue];
	position	= [[sizePos objectAtIndex:1] longValue];

	NSData *source = [NSData dataWithBytes:[gitObject rawContents] length:[gitObject rawContentLen]];
	
	//NSLog(@"SOURCE:%@", source);
	NSMutableData *destination = [NSMutableData dataWithCapacity:destSize];

	while (position < ([deltaData length])) {
		[deltaData getBytes:c range:NSMakeRange(position, 1)];
		//NSLog(@"DS: %d  Pos:%d", destSize, position);
		//NSLog(@"CHR: %d", c[0]);
		
		position += 1;
		if((c[0] & 0x80) != 0) {
			position -= 1;
			cp_off = cp_size = 0;
			
			if((c[0] & 0x01) != 0) {
				[deltaData getBytes:d range:NSMakeRange(position += 1, 1)];
				cp_off = d[0];
			}
			if((c[0] & 0x02) != 0) {
				[deltaData getBytes:d range:NSMakeRange(position += 1, 1)];
				cp_off |= d[0] << 8;
			}
			if((c[0] & 0x04) != 0) {
				[deltaData getBytes:d range:NSMakeRange(position += 1, 1)];
				cp_off |= d[0] << 16;
			}
			if((c[0] & 0x08) != 0) {
				[deltaData getBytes:d range:NSMakeRange(position += 1, 1)];
				cp_off |= d[0] << 24;
			}
			if((c[0] & 0x10) != 0) {
				[deltaData getBytes:d range:NSMakeRange(position += 1, 1)];
				cp_size = d[0];
			}
			if((c[0] & 0x20) != 0) {
				[deltaData getBytes:d range:NSMakeRange(position += 1, 1)];				
				cp_size |= d[0] << 8;
			}
			if((c[0] & 0x40) != 0) {
				[deltaData getBytes:d range:NSMakeRange(position += 1, 1)];
				cp_size |= d[0] << 16;
			}
			if(cp_size == 0)
				cp_size = 0x10000;
			
			position += 1;
			//NSLog(@"pos: %d", position);
			//NSLog(@"offset: %d, %d", cp_off, cp_size);
			
			if(cp_size > buffLength) {
				buffLength = cp_size + 1;
				[buffer setLength:buffLength];
			}

			[source getBytes:[buffer mutableBytes] range:NSMakeRange(cp_off, cp_size)];
			[destination appendBytes:[buffer bytes]	length:cp_size];
			//NSLog(@"dest: %@", destination);
		} else if(c[0] != 0) {
			if(c[0] > destSize) 
				break;
			//NSLog(@"thingy: %d, %d", position, c[0]);
			[deltaData getBytes:[buffer mutableBytes] range:NSMakeRange(position, c[0])];
			[destination appendBytes:[buffer bytes]	length:c[0]];
			position += c[0];
			destSize -= c[0];
		} else {
			 NSLog(@"invalid delta data");
		}
	}
	return destination;
}

- (NSArray *) patchDeltaHeaderSize:(NSData *)deltaData position:(unsigned long)position
{
	unsigned long size = 0;
	int shift = 0;
	unsigned char c[2];
		
	do {
		[deltaData getBytes:c range:NSMakeRange(position, 1)];
		//NSLog(@"read bytes:%d %d", c[0], position);
		position += 1;
		size |= (c[0] & 0x7f) << shift;
		shift += 7;
	} while ( (c[0] & 0x80) != 0 );

	return [NSArray arrayWithObjects:[NSNumber numberWithLong:size], [NSNumber numberWithLong:position], nil];
}

- (NSString *) readServerSha 
{
	char sha[41];
	uint8_t rawsha[20];
	[inStream read:rawsha maxLength:20];
	[ObjGit gitUnpackHex:rawsha fillSha:sha];
	return [[NSString alloc] initWithBytes:sha length:40 encoding:NSASCIIStringEncoding];	
}

- (NSString *) typeString:(int)type {
	if (type == OBJ_COMMIT) 
		return @"commit";
	if (type == OBJ_TREE) 
		return @"tree";
	if (type == OBJ_BLOB)
		return @"blob";
	if (type == OBJ_TAG)
		return @"tag";
	return @"";
}

- (int) typeInt:(NSString *)type {
	if([type isEqualToString:@"commit"])
		return OBJ_COMMIT;
	if([type isEqualToString:@"tree"])
		return OBJ_TREE;
	if([type isEqualToString:@"blob"])
		return OBJ_BLOB;
	if([type isEqualToString:@"tag"])
		return OBJ_TAG;
	return 0;
}

- (NSData *) readData:(int)size {
	// read in the data		
	NSMutableData *decompressed = [NSMutableData dataWithLength: size];
	BOOL done = NO;
	int status;
	
	uint8_t	buffer[2];
	[inStream read:buffer maxLength:1];
	
	z_stream strm;
	strm.next_in = buffer;
	strm.avail_in = 1;
	strm.total_out = 0;
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	
	if (inflateInit (&strm) != Z_OK) 
		NSLog(@"Inflate Issue");
	
	while (!done)
	{
		// Make sure we have enough room and reset the lengths.
		if (strm.total_out >= [decompressed length])
			[decompressed increaseLengthBy: 100];
		strm.next_out = [decompressed mutableBytes] + strm.total_out;
		strm.avail_out = [decompressed length] - strm.total_out;

		// Inflate another chunk.
		status = inflate (&strm, Z_SYNC_FLUSH);
		if (status == Z_STREAM_END) done = YES;
		else if (status != Z_OK) {
			NSLog(@"status for break: %d", status);
			break;
		}

		if(!done) {
			[inStream read:buffer maxLength:1];			
			strm.next_in = buffer;
			strm.avail_in = 1;
		}
	}
	if (inflateEnd (&strm) != Z_OK)
		NSLog(@"Inflate Issue");
	
	// Set real length.
	if (done)
		[decompressed setLength: strm.total_out];
	
	return decompressed;
}

- (int) readPackHeader {
	NSLog(@"read pack header");
	
	uint8_t inSig[4], inVer[4], inEntries[4];
	uint32_t version, entries;
	[inStream read:inSig maxLength:4];
	[inStream read:inVer maxLength:4];
	[inStream read:inEntries maxLength:4];
	
	entries = (inEntries[0] << 24) | (inEntries[1] << 16) | (inEntries[2] << 8) | inEntries[3];
	version = (inVer[0] << 24) | (inVer[1] << 16) | (inVer[2] << 8) | inVer[3];
	if(version == 2)
		return entries;
	else
		return 0;
}

/*
 * write refs to disk after successful read
 */
- (void) writeRefs {
	NSLog(@"write refs");
	NSEnumerator *e = [refsRead objectEnumerator];
	NSArray *thisRef;
	NSString *toSha, *refName, *sendOk;
	
	[self writeServer:@"unpack ok\n"];

	while ( (thisRef = [e nextObject]) ) {
		NSLog(@"ref: %@", thisRef);
		toSha   = [thisRef objectAtIndex:1];
		refName = [thisRef objectAtIndex:2];
		[gitRepo updateRef:refName toSha:toSha];
		sendOk = [NSString stringWithFormat:@"ok %@\n", refName];
		[self writeServer:sendOk];
	}	
}


/*** NETWORK FUNCTIONS ***/

- (void) packetFlush {
	[self sendPacket:@"0000"];
}

- (void) sendPacket:(NSString *)dataWrite {
	NSLog(@"send:[%@]", dataWrite);
	int len = [dataWrite length];
	uint8_t buffer[len];
	[[dataWrite dataUsingEncoding:NSUTF8StringEncoding] getBytes:buffer];
	[outStream write:buffer maxLength:len];
}

// FROM GIT : pkt-line.c : Linus //

#define hex(a) (hexchar[(a) & 15])
- (void) writeServer:(NSString *)dataWrite {
	//NSLog(@"write:[%@]", dataWrite);
	unsigned int len = [dataWrite length];
	len += 4;
	[self writeServerLength:len];
	//NSLog(@"write data");
	[self sendPacket:dataWrite];
}

- (void) writeServerLength:(unsigned int)length 
{
	static char hexchar[] = "0123456789abcdef";
	uint8_t buffer[5];
	
	buffer[0] = hex(length >> 12);
	buffer[1] = hex(length >> 8);
	buffer[2] = hex(length >> 4);
	buffer[3] = hex(length);
	
	//NSLog(@"write len [%c %c %c %c]", buffer[0], buffer[1], buffer[2], buffer[3]);
	[outStream write:buffer maxLength:4];	
}

- (NSString *) packetReadLine {
	uint8_t linelen[4];
	unsigned int len = 0;
	len = [inStream read:linelen maxLength:4];
	
	if(!len) {
		if ([inStream streamStatus] != NSStreamStatusAtEnd)
			NSLog(@"protocol error: read error");
		return nil;
	}
	
	int n;
	len = 0;
	for (n = 0; n < 4; n++) {
		unsigned char c = linelen[n];
		len <<= 4;
		if (c >= '0' && c <= '9') {
			len += c - '0';
			continue;
		}
		if (c >= 'a' && c <= 'f') {
			len += c - 'a' + 10;
			continue;
		}
		if (c >= 'A' && c <= 'F') {
			len += c - 'A' + 10;
			continue;
		}
		NSLog(@"protocol error: bad line length character");
	}
	
	if (!len)
		return @"";
	
	len -= 4;
	uint8_t data[len + 1];
	
	[inStream read:data maxLength:len];
	data[len] = 0;
	
	return [[NSString alloc] initWithBytes:data length:len encoding:NSASCIIStringEncoding];
}

@end
