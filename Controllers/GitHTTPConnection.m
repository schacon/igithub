//
//  This class was created by Nonnus,
//  who graciously decided to share it with the CocoaHTTPServer community.
//

#import "GitHTTPConnection.h"
#import "HTTPServer.h"
#import "HTTPResponse.h"
#import "AsyncSocket.h"

@implementation GitHTTPConnection

/**
 * Returns whether or not the requested resource is browseable.
**/
- (BOOL)isBrowseable:(NSString *)path
{
	return YES;
}


/**
 * This method creates a html browseable page.
 * Customize to fit your needs
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
 * Returns whether or not the server will accept POSTs.
 * That is, whether the server will accept uploaded data for the given URI.
**/
- (BOOL)supportsPOST:(NSString *)path withSize:(UInt64)contentLength
{
	NSLog(@"POST:%@", path);
	
	dataStartIndex = 0;
	multipartData = [[NSMutableArray alloc] init];
	postHeaderOK = FALSE;
	
	return YES;
}


/**
 * This method is called to get a response for a request.
 * You may return any object that adopts the HTTPResponse protocol.
 * The HTTPServer comes with two such classes: HTTPFileResponse and HTTPDataResponse.
 * HTTPFileResponse is a wrapper for an NSFileHandle object, and is the preferred way to send a file response.
 * HTTPDataResopnse is a wrapper for an NSData object, and may be used to send a custom response.
**/
- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	NSLog(@"httpResponseForURI: method:%@ path:%@", method, path);
	
	// getting the service paramater
	NSArray *split = [path componentsSeparatedByString:@"?"];
	NSString *service = @"";
	if ([split count] > 1) {
		service = [split objectAtIndex:1];
		if ([service isEqualToString:@"service=git-receive-pack"]) {
			NSLog(@"receive-pack: %@", service);
			service = @"git-receive-pack";
		}
		if ([service isEqualToString:@"service=git-receive-pack"]) {
			NSLog(@"receive-pack: %@", service);
			service = @"git-upload-pack";
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
			return [self advertiseRefs:repo service:service];             // advertise refs for the project
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

- (NSObject<HTTPResponse> *)advertiseRefs:(NSString *)repository service:(NSString *)service
{
	NSLog(@"advertiseRefs %@:%@", repository, service);

	NSMutableData *outdata = [NSMutableData new];
	NSString *serviceLine = [NSString stringWithFormat:@"# service=%@\n", service];

	[outdata appendData:[self packetData:serviceLine]];
	[outdata appendData:[@"0000" dataUsingEncoding:NSUTF8StringEncoding]];
	[outdata appendData:[self packetData:@"0000000000000000000000000000000000000000 capabilities^{}\0include_tag multi_ack_detailed"]];
	[outdata appendData:[@"0000" dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSLog(@"\n\nREPSONSE:\n%@", outdata);
		
	return [[[HTTPDataResponse alloc] initWithData:outdata] autorelease];
}

- (NSData *)preprocessResponse:(CFHTTPMessageRef)response
{
	//S: Content-Type: application/x-git-upload-pack-advertisement
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Cache-Control"), CFSTR("no-cache"));
	return [super preprocessResponse:response];
}

- (NSData*) packetData:(NSString*) info
{
	return [[self prependPacketLine:info] dataUsingEncoding:NSUTF8StringEncoding];
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

- (NSObject<HTTPResponse> *)receivePack:(NSString *)project
{
	NSLog(@"ACCEPT PACKFILE");
}

- (NSObject<HTTPResponse> *)uploadPack:(NSString *)project
{
	NSLog(@"GENERATE AND TRANSFER PACKFILE");
}

- (NSObject<HTTPResponse> *)plainResponse:(NSString *)project path:(NSString *)path
{	
	NSData *requestData = [(NSData *)CFHTTPMessageCopySerializedMessage(request) autorelease];
	
	NSString *requestStr = [[[NSString alloc] initWithData:requestData encoding:NSASCIIStringEncoding] autorelease];
	NSLog(@"\n=== Request ====================\n%@\n================================", requestStr);
	
	if (requestContentLength > 0)  // Process POST data
	{
		NSLog(@"processing post data: %i", requestContentLength);
		
		if ([multipartData count] < 2) return nil;
		
		NSString* postInfo = [[NSString alloc] initWithBytes:[[multipartData objectAtIndex:1] bytes]
													  length:[[multipartData objectAtIndex:1] length]
													encoding:NSUTF8StringEncoding];
		
		NSArray* postInfoComponents = [postInfo componentsSeparatedByString:@"; filename="];
		postInfoComponents = [[postInfoComponents lastObject] componentsSeparatedByString:@"\""];
		postInfoComponents = [[postInfoComponents objectAtIndex:1] componentsSeparatedByString:@"\\"];
		NSString* filename = [postInfoComponents lastObject];
		
		if (![filename isEqualToString:@""]) //this makes sure we did not submitted upload form without selecting file
		{
			UInt16 separatorBytes = 0x0A0D;
			NSMutableData* separatorData = [NSMutableData dataWithBytes:&separatorBytes length:2];
			[separatorData appendData:[multipartData objectAtIndex:0]];
			int l = [separatorData length];
			int count = 2;	//number of times the separator shows up at the end of file data
			
			NSFileHandle* dataToTrim = [multipartData lastObject];
			NSLog(@"data: %@", dataToTrim);
			
			unsigned long long i;
			for (i = [dataToTrim offsetInFile] - l; i > 0; i--)
			{
				[dataToTrim seekToFileOffset:i];
				if ([[dataToTrim readDataOfLength:l] isEqualToData:separatorData])
				{
					[dataToTrim truncateFileAtOffset:i];
					i -= l;
					if (--count == 0) break;
				}
			}
			
			NSLog(@"NewFileUploaded");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NewFileUploaded" object:nil];
		}
		
		int n;
		for (n = 1; n < [multipartData count] - 1; n++)
			NSLog(@"%@", [[NSString alloc] initWithBytes:[[multipartData objectAtIndex:n] bytes] length:[[multipartData objectAtIndex:n] length] encoding:NSUTF8StringEncoding]);
		
		[postInfo release];
		[multipartData release];
		requestContentLength = 0;
		
	}
	
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


/**
 * This method is called to handle data read from a POST.
 * The given data is part of the POST body.
**/
- (void)processDataChunk:(NSData *)postDataChunk
{
	// Override me to do something useful with a POST.
	// If the post is small, such as a simple form, you may want to simply append the data to the request.
	// If the post is big, such as a file upload, you may want to store the file to disk.
	// 
	// Remember: In order to support LARGE POST uploads, the data is read in chunks.
	// This prevents a 50 MB upload from being stored in RAM.
	// The size of the chunks are limited by the POST_CHUNKSIZE definition.
	// Therefore, this method may be called multiple times for the same POST request.
	
	//NSLog(@"processPostDataChunk");
	
	if (!postHeaderOK)
	{
		UInt16 separatorBytes = 0x0A0D;
		NSData* separatorData = [NSData dataWithBytes:&separatorBytes length:2];
		
		int l = [separatorData length];
		int i;
		for (i = 0; i < [postDataChunk length] - l; i++)
		{
			NSRange searchRange = {i, l};

			if ([[postDataChunk subdataWithRange:searchRange] isEqualToData:separatorData])
			{
				NSRange newDataRange = {dataStartIndex, i - dataStartIndex};
				dataStartIndex = i + l;
				i += l - 1;
				NSData *newData = [postDataChunk subdataWithRange:newDataRange];

				if ([newData length])
				{
					[multipartData addObject:newData];
				}
				else
				{
					postHeaderOK = TRUE;
					
					NSString* postInfo = [[NSString alloc] initWithBytes:[[multipartData objectAtIndex:1] bytes] length:[[multipartData objectAtIndex:1] length] encoding:NSUTF8StringEncoding];
					NSArray* postInfoComponents = [postInfo componentsSeparatedByString:@"; filename="];
					postInfoComponents = [[postInfoComponents lastObject] componentsSeparatedByString:@"\""];
					postInfoComponents = [[postInfoComponents objectAtIndex:1] componentsSeparatedByString:@"\\"];
					NSString* filename = [[[server documentRoot] path] stringByAppendingPathComponent:[postInfoComponents lastObject]];
					NSRange fileDataRange = {dataStartIndex, [postDataChunk length] - dataStartIndex};
					
					[[NSFileManager defaultManager] createFileAtPath:filename contents:[postDataChunk subdataWithRange:fileDataRange] attributes:nil];
					NSFileHandle *file = [[NSFileHandle fileHandleForUpdatingAtPath:filename] retain];

					if (file)
					{
						[file seekToEndOfFile];
						[multipartData addObject:file];
					}
					
					[postInfo release];
					
					break;
				}
			}
		}
	}
	else
	{
		[(NSFileHandle*)[multipartData lastObject] writeData:postDataChunk];
	}
}

@end