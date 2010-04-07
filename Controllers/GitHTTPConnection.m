//
//  This class was created by Nonnus,
//  who graciously decided to share it with the CocoaHTTPServer community.
//

#import "GitHTTPConnection.h"
#import "HTTPServer.h"
#import "HTTPResponse.h"
#import "AsyncSocket.h"
#import "Git.h"
#import "GITRepo.h"
#import "GITPackFile.h"
#import "GITPlaceholderPackFile.h"

@implementation GitHTTPConnection

+ (void)initialize
{
	NSLog(@"init");
	return [super initialize];
}

/**
 * Returns whether or not the requested resource is browseable.
**/
- (BOOL)isBrowseable:(NSString *)path
{
	return YES;
}

/**
 * This method creates a html browseable page.
**/
- (NSString *)createBrowseableIndex:(NSString *)path
{
    NSArray *array = [[NSFileManager defaultManager] directoryContentsAtPath:path];
    
    NSMutableString *outdata = [NSMutableString new];
	[outdata appendString:@"<html><head>"];
	[outdata appendFormat:@"<title>Files from %@</title>", server.name];
    [outdata appendString:@"<style>html {background-color:#eeeeee} body { background-color:#FFFFFF; font-family:Tahoma,Arial,Helvetica,sans-serif; font-size:18x; margin-left:15%; margin-right:15%; border:3px groove #006600; padding:15px; } </style>"];
    [outdata appendString:@"</head><body>"];
	[outdata appendFormat:@"<h1>Files from %@</h1>", server.name];
    [outdata appendString:@"<bq>The following files are hosted live from the iPhone's Docs folder.</bq>"];
    [outdata appendString:@"<p>"];
	[outdata appendFormat:@"<a href=\"..\">..</a><br />\n"];
    for (NSString *fname in array)
    {
        NSDictionary *fileDict = [[NSFileManager defaultManager] fileAttributesAtPath:[path stringByAppendingPathComponent:fname] traverseLink:NO];
		//NSLog(@"fileDict: %@", fileDict);
        NSString *modDate = [[fileDict objectForKey:NSFileModificationDate] description];
		if ([[fileDict objectForKey:NSFileType] isEqualToString: @"NSFileTypeDirectory"]) fname = [fname stringByAppendingString:@"/"];
		[outdata appendFormat:@"<a href=\"%@\">%@</a>		(%8.1f Kb, %@)<br />\n", fname, fname, [[fileDict objectForKey:NSFileSize] floatValue] / 1024, modDate];
    }
    [outdata appendString:@"</p>"];	
	[outdata appendString:@"</body></html>"];
    
	//NSLog(@"outData: %@", outdata);
    return [outdata autorelease];
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)relativePath
{
	NSLog(@"Supports Method: method:%@ path:%@", method, relativePath);

	if ([@"POST" isEqualToString:method])
	{
		return YES;
	}
	
	return [super supportsMethod:method atPath:relativePath];
}

/**
 * This method is called to get a response for a request.
**/
- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	NSLog(@"httpResponseForURI: method:%@ path:%@", method, path);
	
	// getting the service paramater
	NSArray *split = [path componentsSeparatedByString:@"?"];
	gitService = @"";
	if ([split count] > 1) {
		gitService = [split objectAtIndex:1];
		if ([gitService isEqualToString:@"service=git-receive-pack"]) {
			NSLog(@"receive-pack: %@", gitService);
			gitService = @"git-receive-pack";
		}
		if ([gitService isEqualToString:@"service=git-receive-pack"]) {
			NSLog(@"receive-pack: %@", gitService);
			gitService = @"git-upload-pack";
		}		
		path = [split objectAtIndex:0];
	}

	// seperating the project and path
	NSArray *req_path  = [path componentsSeparatedByString:@"/"];
	if ([req_path count] > 2) {
		NSString *repo = [req_path objectAtIndex:1];
		NSLog(@"repo: %@", repo);
		
		NSArray *relPath;
		NSRange theRange;
		theRange.location = 2;
		theRange.length = [req_path count] - 2;
		
		relPath = [req_path subarrayWithRange:theRange];
		NSString *relPathStr = [relPath componentsJoinedByString:@"/"];
		NSLog(@"path: %@", relPathStr);

		if ([relPathStr isEqualToString:@"info/refs"]) {
			return [self advertiseRefs:repo];             // advertise refs for the project
		} else if ([relPathStr isEqualToString:@"git-receive-pack"]) {
			return [self receivePack:repo];                               // accept a packfile (push)
		} else if ([relPathStr isEqualToString:@"git-upload-pack"]) {
			return [self uploadPack:repo];                                // create and transfer a packfile (fetch)
		} else {
			return [self plainResponse:repo path:relPathStr];             // dumb request
		}
	} else if ([req_path count] > 1) {
		// no path listed, just the project
		NSString *repo = [req_path objectAtIndex:1];
		return [self plainResponse:repo path:@"/"];
	}

	// home index request
	return [self indexPage];
}

- (NSObject<HTTPResponse> *)indexPage
{
	NSLog(@"indexPage");
	NSData *browseData = [[self createBrowseableIndex:@"/"] dataUsingEncoding:NSUTF8StringEncoding];
	return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];	
}

- (NSObject<HTTPResponse> *)advertiseRefs:(NSString *)repository
{
	NSLog(@"advertiseRefs %@:%@", repository, gitService);

	NSMutableData *outdata = [NSMutableData new];
	NSString *serviceLine = [NSString stringWithFormat:@"# service=%@\n", gitService];

	GITRepo	*gitRepo;
	NSString* gitPath = [self gitRoot:repository];
	if (![[NSFileManager defaultManager] fileExistsAtPath:gitPath]) {
		if([gitService isEqualToString:@"git-receive-pack"]) {
			// create the repository when you first try to push to it, if it doesn't exist
			NSLog(@"create repo");
			NSLog(@"path: %@", gitPath);
			[GITRepo initGitRepo:gitPath];
		}
	} else {
		// TODO: initialize git repo for ref reading
	}
	gitRepo = [[GITRepo alloc] initWithRoot:gitPath];
	NSLog(@"repo: %@", gitRepo);

	// TODO: actually read from Git repository
	[outdata appendData:[self packetData:serviceLine]];
	[outdata appendData:[@"0000" dataUsingEncoding:NSUTF8StringEncoding]];
	[outdata appendData:[self packetData:@"0000000000000000000000000000000000000000 capabilities^{}\0include_tag multi_ack_detailed"]];
	[outdata appendData:[@"0000" dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSLog(@"\n\nREPSONSE:\n%@", outdata);
		
	return [[[HTTPDataResponse alloc] initWithData:outdata] autorelease];
}

- (NSData *)preprocessResponse:(CFHTTPMessageRef)response
{
	NSString *contentType = [NSString stringWithFormat:@"application/x-git-%@-advertisement", gitService];
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Type"), (CFStringRef)contentType);
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Cache-Control"), CFSTR("no-cache"));
	return [super preprocessResponse:response];
}



- (NSObject<HTTPResponse> *)receivePack:(NSString *)project
{
	NSLog(@"ACCEPT PACKFILE");

	NSData *requestData = [(NSData *)CFHTTPMessageCopySerializedMessage(request) autorelease];
	NSString *requestStr = [[[NSString alloc] initWithData:requestData encoding:NSASCIIStringEncoding] autorelease];
	NSLog(@"\n=== Request ====================\n%@\n================================", requestStr);
	
	NSLog(@"file offset: %d", [packfile offsetInFile]);
	if([packfile offsetInFile] == 0) {
		return nil;
	}
	
	GITRepo *repo = [[GITRepo alloc] initWithRoot:[self gitRoot:project]];
	NSLog(@"repo: %@", repo);
	
	[packfile seekToFileOffset:0];

	// read refs
	NSMutableArray*			refsRead;
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

	// readPack
	NSData *pack = [[packfile readDataToEndOfFile] autorelease];
	NSLog(@"data: %@", pack);
	GITPackFile *packf = [[GITPackFile alloc] initWithData:pack error:NULL];
	NSLog(@"data: %@", packf);

	NSLog(@"checksum : %@", [packf checksumString]);
	NSLog(@"obj count: %@", [packf numberOfObjects]);
	NSLog(@"done");
	
	// TODO: explode packfile if it's too small (number of objects)

	// writeRefs
	// send updated refs (oks)
	// packetFlush
	
	return nil;
}


- (NSString *) packetReadLine {
	NSData* length = [packfile readDataOfLength:4];
	NSLog(@"%@", length);
	uint8_t *linelen;
	linelen = [length bytes];

	int n;
	int len = 0;
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
	NSData* data = [packfile readDataOfLength:len];	
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}


- (NSObject<HTTPResponse> *)uploadPack:(NSString *)project
{
	NSLog(@"GENERATE AND TRANSFER PACKFILE");
	return nil;
}


- (NSObject<HTTPResponse> *)plainResponse:(NSString *)project path:(NSString *)path
{	
	NSData *requestData = [(NSData *)CFHTTPMessageCopySerializedMessage(request) autorelease];
	NSString *requestStr = [[[NSString alloc] initWithData:requestData encoding:NSASCIIStringEncoding] autorelease];
	NSLog(@"\n=== Request ====================\n%@\n================================", requestStr);
	
	NSString *filePath = [self filePathForURI:path];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
	{
		return [[[HTTPFileResponse alloc] initWithFilePath:filePath] autorelease];
	}
	else
	{
		NSString *folder = [path isEqualToString:@"/"] ? [[server documentRoot] path] : [NSString stringWithFormat: @"%@%@", [[server documentRoot] path], path];

		if ([self isBrowseable:folder])
		{
			NSLog(@"folder: %@", folder);
			NSData *browseData = [[self createBrowseableIndex:folder] dataUsingEncoding:NSUTF8StringEncoding];
			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
		} else {
			NSLog(@"Something else");
		}
	}
	
	return nil;
}


// TODO: Add random and move to temp?
- (void)prepareForBodyWithSize:(UInt64)contentLength
{
	NSString* packfilePath = [self gitTmp:@"pack-upload.data"];
	NSLog(@"PREPARE %@", packfilePath);
	[[NSFileManager defaultManager] createFileAtPath: packfilePath
											contents: nil attributes: nil];
	packfile = [[NSFileHandle fileHandleForUpdatingAtPath:packfilePath] retain];
	[packfile truncateFileAtOffset: 0];
}

- (NSString *)gitRoot:(NSString *)project;
{
	NSArray *paths;
	NSString *tmpPath = @"";
	paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	tmpPath = [NSString stringWithString:[[paths objectAtIndex:0] stringByAppendingPathComponent:@"git"]];
	return [tmpPath stringByAppendingPathComponent:project];
}

- (NSString *)gitTmp:(NSString *)project;
{
	NSArray *paths;
	NSString *tmpPath = @"";
	paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	tmpPath = [NSString stringWithString:[[paths objectAtIndex:0] stringByAppendingPathComponent:@"gitTmp"]];
	return [tmpPath stringByAppendingPathComponent:project];
}

/**
 * This method is called to handle data read from a POST.
 * The given data is part of the POST body.
**/
- (void)processDataChunk:(NSData *)postDataChunk
{
	[packfile writeData:postDataChunk];
}


#define hex(a) (hexchar[(a) & 15])
- (NSString*) prependPacketLine:(NSString*) info
{
	static char hexchar[] = "0123456789abcdef";
	uint8_t buffer[5];
	
	unsigned int length = [info length] + 4;
	
	buffer[0] = hex(length >> 12);
	buffer[1] = hex(length >> 8);
	buffer[2] = hex(length >> 4);
	buffer[3] = hex(length);
	
	NSLog(@"write len [%c %c %c %c]", buffer[0], buffer[1], buffer[2], buffer[3]);
	
	NSData *data=[[NSData alloc] initWithBytes:buffer length:4];
	NSString *lenStr = [[NSString alloc] 
						initWithData:data
						encoding:NSUTF8StringEncoding];
	
	return [NSString stringWithFormat:@"%@%@", lenStr, info];
}


- (NSData*) packetData:(NSString*) info
{
	return [[self prependPacketLine:info] dataUsingEncoding:NSUTF8StringEncoding];
}


@end