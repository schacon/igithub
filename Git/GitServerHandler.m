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
#import "GitObject.h"
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
	
	//NSLog(@"\nTYPE: %d\n", type);
	//NSLog(@"size: %d\n", size);
	
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
			GitObject *object;
			object = [gitRepo getObjectFromSha:sha1];
			contents = [self patchDelta:objectData withObject:object];
			[gitRepo writeObject:contents withType:[self typeString:type] withSize:size];
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

- (NSData *) patchDelta:(NSData *)deltaData withObject:(GitObject *)gitObject
{
	int sourceSize, destSize, position;
	int cp_off, cp_size;
	unsigned char c[2], d[2];
	
	int buffLength = 1000;
	NSMutableData *buffer = [[NSMutableData alloc] initWithCapacity:buffLength];
	
	NSArray *sizePos = [self patchDeltaHeaderSize:deltaData position:0];
	sourceSize	= [[sizePos objectAtIndex:0] intValue];
	position	= [[sizePos objectAtIndex:1] intValue];
	
	sizePos = [self patchDeltaHeaderSize:deltaData position:position];
	destSize	= [[sizePos objectAtIndex:0] intValue];
	position	= [[sizePos objectAtIndex:1] intValue];

	//NSLog(@"DS: %d  Pos:%d", destSize, position);

	NSData *source = [NSData dataWithBytes:[[gitObject contents] UTF8String] length:[gitObject size]];
	NSMutableData *destination = [NSMutableData dataWithCapacity:destSize];

	while (position < ([deltaData length] - 1)) {
		[deltaData getBytes:c range:NSMakeRange(position, 1)];
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
		} else if(c[0] != 0) {
			//NSLog(@"thingy: %d, %d", position, c[0]);
			[source getBytes:[buffer mutableBytes] range:NSMakeRange(position, c[0])];
			[destination appendBytes:[buffer bytes]	length:c[0]];
			position += c[0];
		} else {
			 NSLog(@"invalid delta data");
		}
	}
	return [NSData dataWithBytes:destination length:[destination length]];
}

- (NSArray *) patchDeltaHeaderSize:(NSData *)deltaData position:(int)position
{
	int size = 0;
	int shift = 0;
	unsigned char c[2];
		
	do {
		[deltaData getBytes:c range:NSMakeRange(position, 1)];
		position += 1;
		size |= (c[0] & 0x7f) << shift;
		shift += 7;
	} while ( (c[0] & 0x80) != 0 );

	return [NSArray arrayWithObjects:[NSNumber numberWithInt:size], [NSNumber numberWithInt:position], nil];
}

- (NSString *) readServerSha 
{
	char sha[41];
	uint8_t rawsha[20];
	[inStream read:rawsha maxLength:20];
	[Git gitUnpackHex:rawsha fillSha:sha];
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
	uint8_t data[len + 1];
	
	[inStream read:data maxLength:len];
	data[len] = 0;
	
	return [[NSString alloc] initWithBytes:data length:len encoding:NSASCIIStringEncoding];
}

@end
