//
//  NSDataCompression.h
//  ObjGit
//

#include <Foundation/Foundation.h>

@interface NSData (Compression)

- (NSData *) compressedData;
- (NSData *) decompressedData;

@end
