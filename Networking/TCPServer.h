/*

File: TCPServer.h
Abstract: A TCP server that listens on an arbitrary port.

Version: 1.5

*/

#import <Foundation/Foundation.h>

//CLASSES:

@class TCPServer;

//ERRORS:

NSString * const TCPServerErrorDomain;

typedef enum {
    kTCPServerCouldNotBindToIPv4Address = 1,
    kTCPServerCouldNotBindToIPv6Address = 2,
    kTCPServerNoSocketsAvailable = 3,
} TCPServerErrorCode;

//PROTOCOLS:

@protocol TCPServerDelegate <NSObject>
@optional
- (void) serverDidEnableBonjour:(TCPServer*)server withName:(NSString*)name;
- (void) server:(TCPServer*)server didNotEnableBonjour:(NSDictionary *)errorDict;
- (void) didAcceptConnectionForServer:(TCPServer*)server inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;
@end

//CLASS INTERFACES:

@interface TCPServer : NSObject {
@private
	id _delegate;
    uint16_t _port;
	CFSocketRef _ipv4socket;
	NSNetService* _netService;
}
	
- (BOOL)start:(NSError **)error;
- (BOOL)stop;
- (BOOL) enableBonjourWithDomain:(NSString*)domain applicationProtocol:(NSString*)protocol name:(NSString*)name; //Pass "nil" for the default local domain - Pass only the application protocol for "protocol" e.g. "myApp"
- (void) disableBonjour;

@property(assign) id<TCPServerDelegate> delegate;

+ (NSString*) bonjourTypeFromIdentifier:(NSString*)identifier;

@end
