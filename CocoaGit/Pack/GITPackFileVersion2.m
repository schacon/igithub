//
//  GITPackFileVersion2.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 04/11/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITPackFileVersion2.h"
#import "GITPackFile.h"
#import "GITPackIndex.h"
#import "GITUtilityBelt.h"
#import "NSData+Hashing.h"
#import "NSData+Compression.h"
#import "NSData+Patching.h"

static const NSRange kGITPackFileObjectCountRange = { 8, 4 };



/*! \cond */
@interface GITPackFileVersion2 ()
@property(readwrite,copy) NSString * path;
@property(readwrite,retain) NSData * data;
@property(readwrite,retain) GITPackIndex * index;
- (NSUInteger) readHeaderAtOffset:(off_t)offset type:(NSUInteger *)type size:(NSUInteger *)sizep;
- (NSUInteger) sizeOfPackedDataFromOffset:(off_t)currentOffset;
- (NSData *) unpackObjectAtOffset:(off_t)offset type:(GITObjectType*)objectType error:(NSError**)error;
- (NSData *) unpackDeltifiedObjectAtOffset:(off_t)offset type:(GITObjectType)deltaType objectOffset:(off_t)objOffset objectType:(GITObjectType *)type error:(NSError**)error;
- (NSData *) packedDataForObjectWithSha1:(NSString *)sha1;
- (NSRange)rangeOfPackedObjects;
- (NSRange)rangeOfChecksum;
- (NSData*)checksum;
- (NSString*)checksumString;
- (BOOL)verifyChecksum;
@end
/*! \endcond */

@implementation GITPackFileVersion2
@synthesize path;
@synthesize data;
@synthesize index;

#pragma mark -
#pragma mark Primitive Methods
- (void) dealloc
{
    [path release], path = nil;
    [data release], data = nil;
    [index release], index = nil;
    [super dealloc];
}

- (NSUInteger)version
{
    return 2;
}
- (id)initWithData:(NSData *)packData error:(NSError **)error;
{
    if (! [super init])
        return nil;
    
    if (!packData) {
        [self release];
        return nil;
    }
    
    [self setData:packData];
        
    return self;
}

- (id)initWithPath:(NSString*)thePath indexPath:(NSString *)idxPath error:(NSError **)error;
{
    NSData *packData = [NSData dataWithContentsOfFile:thePath
                                              options:NSMappedRead
                                                error:error];    
    if (! packData)
        return nil;
    
    if (! [self initWithData:packData error:error])
        return nil;
    
    self.path = thePath;
    self.index  = [GITPackIndex packIndexWithPath:idxPath error:error];
    
    if (! index) {
        [self release];
        return nil;
    }
    
    return self;
}

- (id)initWithPath:(NSString*)thePath error:(NSError **)error
{
    NSString * idxPath = [[thePath stringByDeletingPathExtension]
                          stringByAppendingPathExtension:@"idx"];
    return [self initWithPath:thePath indexPath:idxPath error:error];
}

- (NSUInteger)numberOfObjects
{
    if (!numberOfObjects)
    {
        uint32_t value;
        [self.data getBytes:&value range:kGITPackFileObjectCountRange];
        numberOfObjects = CFSwapInt32BigToHost(value);
    }
    return numberOfObjects;
}

- (NSData *) packedDataForObjectWithSha1:(NSString *)sha1
{
    if (![self hasObjectWithSha1:sha1]) return nil;
    if (! self.index) return nil;
    
    off_t offset = [[self index] packOffsetForSha1:sha1];
    NSUInteger size = [self sizeOfPackedDataFromOffset:offset];
    return [[self data] subdataWithRange:NSMakeRange(offset, size)];
}

- (NSData*)dataForObjectWithSha1:(NSString*)sha1
{
    // We've defined it this way so if we can determine a better way
    // to test for hasObjectWithSha1 then packOffsetForSha1 > 0
    // then we can simply change the implementation in GITPackIndex.
    if (![self hasObjectWithSha1:sha1]) return nil;
    
    if (! self.index) return nil;
    
    NSData *objData;
    NSUInteger type;
    if (! [self loadObjectWithSha1:sha1 intoData:&objData type:&type error:NULL])
        return nil;
    
    return objData;
}

- (BOOL)loadObjectWithSha1:(NSString*)sha1 intoData:(NSData**)objectData
                      type:(GITObjectType*)objectType error:(NSError**)error
{
    NSAssert(objectData != NULL, @"NULL pointer supplied for objectData");
    NSAssert(objectType != NULL, @"NULL pointer supplied for objectType");
    
    if (! self.index) {
        GITError(error, GITErrorPackIndexNotAvailable, @"This packfile is not indexed");
    }
    
    NSUInteger offset = [self.index packOffsetForSha1:sha1 error:error];
    if (offset == NSNotFound)
        return NO;

    NSData *objData = [self unpackObjectAtOffset:offset type:objectType error:error];
    if (! objData)
        return NO;
    
    *objectData = objData;
    return YES;
}


#pragma mark -
#pragma mark Internal Methods

- (NSUInteger) sizeOfPackedDataFromOffset:(off_t)currentOffset;
{
    off_t nextOffset = [self.index nextOffsetWithOffset:currentOffset];
    if ( nextOffset == -1 ) {
        NSRange checksumRange = [self rangeOfChecksum];
        nextOffset = (off_t)(checksumRange.location);
    }
    return (nextOffset - currentOffset);
}

- (NSUInteger) readHeaderAtOffset:(off_t)offset type:(NSUInteger *)type size:(NSUInteger *)sizep;
{
    uint8_t buf;
    NSUInteger size, shift = 4;
    off_t pos = offset;
    [self.data getBytes:&buf range:NSMakeRange(pos++, 1)];
    
    size = buf & 0xf;
    *type = (buf >> 4) & 0x7;
	
	while ((buf & 0x80) != 0) {
		[self.data getBytes:&buf range:NSMakeRange(pos++, 1)];		
		size |= ((buf & 0x7f) << shift);
		shift += 7;
	}
    
    *sizep = size;
    
    return pos-offset;
}

- (NSData *)unpackObjectAtOffset:(off_t)offset type:(GITObjectType*)objectType error:(NSError**)error;
{
    off_t objOffset = offset;
        
    NSUInteger size, type;
    NSUInteger headerLength = [self readHeaderAtOffset:offset type:&type size:&size];
    offset += headerLength;
    NSUInteger packedSize = [self sizeOfPackedDataFromOffset:offset];
    
    NSData *objData;
	switch (type) {
		case kGITPackFileTypeCommit:
		case kGITPackFileTypeTree:
		case kGITPackFileTypeTag:
		case kGITPackFileTypeBlob:
            objData = [[self.data subdataWithRange:NSMakeRange(offset, packedSize)] zlibInflate];
            if (objData && type && (size != [objData length])) {
                GITError(error, GITErrorObjectSizeMismatch, NSLocalizedString(@"Object size mismatch", @"GITErrorObjectSizeMismatch"));
                return nil;
            }
            *objectType = type;
			break;
		case kGITPackFileTypeDeltaOfs:
        case kGITPackFileTypeDeltaRefs:
            objData = [self unpackDeltifiedObjectAtOffset:offset type:type objectOffset:objOffset objectType:objectType error:error];
            break;
    }
    
    return objData;
}

- (NSData *)unpackDeltifiedObjectAtOffset:(off_t)offset type:(GITObjectType)deltaType objectOffset:(off_t)objOffset objectType:(GITObjectType *)type error:(NSError**)error;
{
    NSData *packedData = [self.data subdataWithRange:NSMakeRange(offset, 20)];
    
    off_t baseOffset;
    if (deltaType == kGITPackFileTypeDeltaRefs) {
        offset += 20;
        baseOffset = [self.index packOffsetForSha1:unpackSHA1FromData(packedData) error:error];
    } else if (deltaType == kGITPackFileTypeDeltaOfs) {
        NSUInteger used = 0;
        const uint8_t *bytes = [packedData bytes];
        uint8_t c = bytes[used++];
        baseOffset = c & 127;        
        while ((c & 128) != 0) {
            baseOffset++;
            c = bytes[used++];
            baseOffset <<= 7;
            baseOffset += (c & 127);
        }
        baseOffset = objOffset - baseOffset;
        offset += used;        
    }
    
    NSData *baseObjectData = [self unpackObjectAtOffset:baseOffset type:type error:error];
    if (! baseObjectData) {
        GITError(error, GITErrorObjectNotFound, NSLocalizedString(@"Base Object not found for PACK delta", @"GITErrorObjectNotFound (GITPackFile)"));
        return nil;
    }
    
    [baseObjectData retain];
    NSUInteger packedSize = [self sizeOfPackedDataFromOffset:offset];
    NSData *deltaData = [[self.data subdataWithRange:NSMakeRange(offset, packedSize)] zlibInflate];
    NSData *objData = [baseObjectData dataByPatchingWithDelta:deltaData];
    [baseObjectData release];
    
    return objData;
}

- (NSRange)rangeOfPackedObjects
{
    return NSMakeRange(12, [self rangeOfChecksum].location - 12);
}

- (NSRange)rangeOfChecksum
{
    return NSMakeRange([self.data length] - 20, 20);
}

- (NSData*)checksum
{
    return [self.data subdataWithRange:[self rangeOfChecksum]];
}

- (NSString*)checksumString
{
    return unpackSHA1FromData([self checksum]);
}

- (BOOL)verifyChecksum
{
    NSData * checkData = [[self.data subdataWithRange:NSMakeRange(0, [self.data length] - 20)] sha1Digest];
    return [checkData isEqualToData:[self checksum]];
}
@end
