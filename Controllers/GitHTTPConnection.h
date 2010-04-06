//
//  This class was created by Nonnus,
//  who graciously decided to share it with the CocoaHTTPServer community.
//

#import <Foundation/Foundation.h>
#import "HTTPConnection.h"


@interface GitHTTPConnection : HTTPConnection
{
	int dataStartIndex;
	NSMutableArray* multipartData;
	BOOL postHeaderOK;
}

- (BOOL)isBrowseable:(NSString *)path;
- (NSString *)createBrowseableIndex:(NSString *)path;

- (NSObject<HTTPResponse> *)indexPage;
- (NSObject<HTTPResponse> *)plainResponse:(NSString *)project path:(NSString *)path;

- (NSObject<HTTPResponse> *)advertiseRefs:(NSString *)repository service:(NSString *)service;

- (NSObject<HTTPResponse> *)receivePack:(NSString *)project;
- (NSObject<HTTPResponse> *)uploadPack:(NSString *)project;

- (NSData*) packetData:(NSString*) info;
- (NSString*) prependPacketLine:(NSString*) info;

- (BOOL)supportsPOST:(NSString *)path withSize:(UInt64)contentLength;


@end