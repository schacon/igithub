//
//  GitServerHandler.m
//  ObjGit
//

#define NULL_SHA @"0000000000000000000000000000000000000000"
#define CAPABILITIES @" "

#define OBJ_NONE	  0
#define OBJ_COMMIT	  1
#define OBJ_TREE	  2
#define OBJ_BLOB	  3
#define OBJ_TAG		  4
#define OBJ_OFS_DELTA 6
#define OBJ_REF_DELTA 7

#import "Git.h"
#import "GitServerHandler.h"

@implementation GitServerHandler

@synthesize inStream;
@synthesize outStream;
@synthesize gitRepo;

@synthesize refsRead;
@synthesize capabilitiesSent;

- (void) initWithGit:(Git *)git input:(NSInputStream *)streamIn output:(NSOutputStream *)streamOut
{
	gitRepo		= git;
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
	NSString *header, *command, *repository;
	header = [self packetReadLine];
	NSLog(@"header: %@", header);
	
	NSArray *values = [header componentsSeparatedByString:@" "];
	command		= [values objectAtIndex: 0];			
	repository	= [values objectAtIndex: 1];
	NSLog(@"header: %@ : %@", command, repository);
	
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

	/*
	 @git_dir = File.join(@path, path)
	 git_init(@git_dir) if !File.exists?(@git_dir)
	 */
	 
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
	   // send_ref("capabilities^{}", NULL_SHA) if !@capabiliies_sent
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
	int entries = [self readPackHeader];
	[self unpackAll:entries];
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
	NSLog(@"entfin : %d", entries);
	NSLog(@"version: %d", version);
	return entries;
}

- (void) unpackAll:(int)entries {
	NSLog(@"unpack all : %d", entries);
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
