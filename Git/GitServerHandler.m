//
//  GitServerHandler.m
//  ObjGit
//

#define NULL_SHA @"0000000000000000000000000000000000000000"
#define CAPABILITIES @" "

#define OBJ_NONE	0
#define OBJ_COMMIT	1
#define OBJ_TREE	2
#define OBJ_BLOB	3
#define OBJ_TAG		4
#define OBJ_OFS_DELTA 6
#define OBJ_REF_DELTA 7

#import "Git.h"
#import "GitServerHandler.h"
#include <zlib.h>

@implementation GitServerHandler

@synthesize inStream;
@synthesize outStream;
@synthesize gitRepo;
@synthesize gitPath;

@synthesize refsRead;
@synthesize capabilitiesSent;

- (void) initWithGit:(Git *)git gitPath:(NSString *)gitRepoPath input:(NSInputStream *)streamIn output:(NSOutputStream *)streamOut
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
		NSLog(@"RECEIVE-PACK");
		[self receivePack:repository];
	} else if ([command isEqualToString: @"git-upload-pack"]) {	// git fetch //
		NSLog(@"UPLOAD-PACK not implemented yet");
		//[self upload-pack:repository];
	}

}

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
}


/*** RECEIVE-PACK FUNCTIONS ***/

- (void) sendRefs {
	NSLog(@"send refs");

	// get refs from gitRepo		//
	// foreach ref, send to client	//
	/*
	 refs.each do |ref|
	 send_ref(ref[1], ref[0])
	 end
	 */

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
		sendData = [[NSString alloc] initWithFormat:@"%@ %@%c%@\n", shaString, refName, 0, CAPABILITIES];
	[self writeServer:sendData];
	capabilitiesSent = 1;
}

- (void) readRefs {
	NSString *data;
	NSLog(@"read refs");
	data = [self packetReadLine];
	while([data length] > 0) {
		NSArray  *values  = [data componentsSeparatedByString:@" "];
		[refsRead addObject: values];  // save the refs for writing later
		
		/* DEBUGGING */
		NSLog(@"ref: [%@ : %@ : %@]", [values objectAtIndex: 0], \
			  [values objectAtIndex: 1], [values objectAtIndex: 2]);
		
		data = [self packetReadLine];
	}
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
} 

- (void) unpackObject {
	NSLog(@"unpack object");
	
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
	
	NSLog(@"\nTYPE: %d\n", type);
	NSLog(@"size: %d\n", size);
	
	if((type == OBJ_COMMIT) || (type == OBJ_TREE) || (type == OBJ_BLOB) || (type == OBJ_TAG)) {
		NSData *objectData;
		objectData = [self readData:size];
		[gitRepo writeObject:objectData withType:[self typeString:type] withSize:size];
		// TODO : check saved delta objects
	} else if ((type == OBJ_REF_DELTA) || (type == OBJ_OFS_DELTA)) {
		NSLog(@"NO SUPPORT FOR DELTAS YET");
	} else {
		NSLog(@"bad object type %d", type);
	}
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
	return entries;
}

/*
 * write refs to disk after successful read
 */
- (void) writeRefs {
	NSLog(@"write refs");
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
	NSLog(@"write:[%@]", dataWrite);
	unsigned int len = [dataWrite length];
		
	static char hexchar[] = "0123456789abcdef";
	uint8_t buffer[4];
	
	len += 4;
	buffer[0] = hex(len >> 12);
	buffer[1] = hex(len >> 8);
	buffer[2] = hex(len >> 4);
	buffer[3] = hex(len);
	
	NSLog(@"write len");
	[outStream write:buffer maxLength:4];
	NSLog(@"write data");
	[self sendPacket:dataWrite];
}

- (NSString *) packetReadLine {
	uint8_t linelen[4];
	unsigned int len = 0;
	len = [inStream read:linelen maxLength:4];
	
	if(!len) {
		if ([inStream streamStatus] != NSStreamStatusAtEnd)
			NSLog(@"protocol error: read error");
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
	uint8_t data[len];
	
	[inStream read:data maxLength:len];
	data[len] = 0;
	
	return [[NSString alloc] initWithBytes:data length:len encoding:NSASCIIStringEncoding];
}

@end
