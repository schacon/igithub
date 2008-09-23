//
//  NSDataCompression.h
//  ObjGit
//
//  thankfully borrowed from the Etoile framework
//

#include <Foundation/Foundation.h>

@interface NSData (Compression)

- (NSData *) compressedData;
- (NSData *) decompressedData;

@end
