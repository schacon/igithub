//
//  GITPackIndexVersion2.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 04/11/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITPackIndexVersion2.h"
#import "GITPackReverseIndex.h"
#import "GITUtilityBelt.h"
#import "NSData+Hashing.h"
#import "GITErrors.h"

static const NSRange kGITPackIndexSignature             = {0, 4};
static const NSRange kGITPackIndexVersion               = {4, 4};

static const NSRange kGITPackIndexFanout                = {8, 256 * 4};
static const NSUInteger kGITPackIndexFanoutSize         = 4;
static const NSUInteger kGITPackIndexFanoutCount        = 256;

static const NSUInteger kGITPackIndexSHASize            = 20;
static const NSUInteger kGITPackIndexCRCSize            = 4;
static const NSUInteger kGITPackIndexOffsetSize         = 4;
static const NSUInteger kGITPackIndexExtendedOffsetSize = 8;

/*! \cond */
@interface GITPackIndexVersion2 ()
- (NSArray*)loadOffsetsWithError:(NSError**)error;
- (NSRange)rangeOfSignature;
- (NSRange)rangeOfVersion;
- (NSRange)rangeOfFanoutTable;
- (NSRange)rangeOfSHATable;
- (NSRange)rangeOfCRCTable;
- (NSRange)rangeOfOffsetTable;
- (NSRange)rangeOfExtendedOffsetTable;
- (NSRange)rangeOfPackChecksum;
- (NSRange)rangeOfChecksum;
- (off_t)packOffsetWithIndex:(NSUInteger)i;
- (GITPackReverseIndex *)revIndex;
- (NSString *)sha1WithOffset:(off_t)offset;
- (NSData *)packedSha1WithIndex:(NSUInteger)i;
@end
/*! \endcond */

@implementation GITPackIndexVersion2
@synthesize path;
@synthesize data;

- (id)initWithPath:(NSString*)thePath error:(NSError**)outError
{
    if (! [super init])
        return nil;

    self.path = thePath;
    self.data = [NSData dataWithContentsOfFile:thePath
                                       options:NSMappedRead
                                         error:outError];
    if (! [self verifyChecksum]) {
        NSString * errDesc = NSLocalizedString(@"PACK Index file checksum failed", @"GITErrorPackIndexChecksumMismatch");
        GITErrorWithInfo(outError, GITErrorPackIndexChecksumMismatch, errDesc, NSLocalizedDescriptionKey, thePath, NSFilePathErrorKey, nil);
        [self release];
        return nil;
    }
        
    return self;
}
- (void)dealloc
{
    self.path = nil;
    self.data = nil;
    [offsets release], offsets = nil;
    [revIndex release], revIndex = nil;
    [super dealloc];
}
- (id)copyWithZone:(NSZone *)zone
{
    if (NSShouldRetainWithZone(self, zone))
        return [self retain];
    else
        return [super copyWithZone:zone];
}
- (NSUInteger)version
{
    return 2;
}

- (GITPackReverseIndex *)revIndex;
{
    if (! revIndex) {
        revIndex = [[GITPackReverseIndex alloc] initWithPackIndex:self];
    }
    return revIndex;
}

#pragma mark -
#pragma mark KVC/KVO array accessor methods
- (NSUInteger) countOfSha1s;
{
    return [self numberOfObjects];
}

- (NSString *) objectInSha1sAtIndex:(NSUInteger)i;
{
    NSData *packedSha1 = [self packedSha1WithIndex:i];
    if ( !packedSha1 )
        return nil;
    return unpackSHA1FromData(packedSha1);
}

- (NSArray *) sha1s;
{
    NSUInteger count = [self countOfSha1s];
    NSMutableArray *sha1s = [NSMutableArray arrayWithCapacity:count];

    NSUInteger i;
    for (i = 0; i < count; i++) {
        [sha1s addObject:[self objectInSha1sAtIndex:i]];
    }
    return [NSArray arrayWithArray:sha1s];
}

- (NSUInteger) countOfCRCs;
{
    return [self numberOfObjects];
}

- (NSData *) objectInCRCsAtIndex:(NSUInteger)i;
{
    NSRange crcRange = [self rangeOfCRCTable];
    NSUInteger positionFromStart = i * kGITPackIndexCRCSize;
    
    if (positionFromStart < crcRange.length)
    {
        return [self.data subdataWithRange:NSMakeRange(crcRange.location + positionFromStart, kGITPackIndexCRCSize)];
    }
    return nil;
}

- (NSArray *) CRCs;
{
    NSUInteger count = [self countOfCRCs];
    NSMutableArray *CRCs = [NSMutableArray arrayWithCapacity:count];
    
    NSUInteger i;
    for (i = 0; i < count; i++) {
        [CRCs addObject:[self objectInCRCsAtIndex:i]];
    }
    return [NSArray arrayWithArray:CRCs];
}

- (NSArray*)offsets
{
    if (!offsets)
        offsets = [[self loadOffsetsWithError:NULL] copy];
    return offsets;
}
- (NSArray*)loadOffsetsWithError:(NSError**)error
{
    uint32_t value;
    NSUInteger i, lastCount, thisCount;
    NSMutableArray * _offsets = [NSMutableArray arrayWithCapacity:256];

    lastCount = thisCount = 0;
    for (i = 0; i < kGITPackIndexFanoutCount; i++)
    {
        NSRange range = NSMakeRange(i * kGITPackIndexFanoutSize +
            [self rangeOfFanoutTable].location, kGITPackIndexFanoutSize);
        [self.data getBytes:&value range:range];
        thisCount = CFSwapInt32BigToHost(value);
        
        if (lastCount > thisCount)
        {
            NSString * format = NSLocalizedString(@"Index: %@ : Invalid fanout %lu -> %lu for entry %d", @"GITErrorPackIndexCorrupted");
            NSString * reason = [NSString stringWithFormat:format, [self.path lastPathComponent], lastCount, thisCount, i];
            GITError(error, GITErrorPackIndexCorrupted, reason);
            return nil;
        }

        [_offsets addObject:[NSNumber numberWithUnsignedInteger:thisCount]];
        lastCount = thisCount;
    }
    return [[_offsets copy] autorelease];
}
// The sha1 to offset mapping in v2 Index files works like this
//  - the fanout table tells you where in the main entry table you can find SHA's with a specific first byte
//  - the main sha1 list table gives you a sorted list of SHA1's in the Index and Pack file. The array index
//    of the SHA1 in this table equates to the array index of the pack offset in the offsets table.

- (NSUInteger) indexOfSha1:(NSString *)sha1
{
    const uint8_t *packedSha1 = [(NSData *)packSHA1(sha1) bytes];
    const uint8_t *sha1Data = [[self data] bytes]; 
    
    NSRange rangeOfShas = [self rangeOfObjectsWithFirstByte:packedSha1[0]];
    if (rangeOfShas.length > 0) {
        NSUInteger lo = rangeOfShas.location;
        NSUInteger hi = lo + rangeOfShas.length;
        NSUInteger location = [self rangeOfSHATable].location;
        do {
            NSUInteger mid = (lo + hi) >> 1; // divide by 2 ;)
            NSUInteger position = (mid * kGITPackIndexSHASize) + location;
            int cmp = memcmp(packedSha1, sha1Data + position, kGITPackIndexSHASize);
            if ( cmp < 0 ) {
                hi = mid;
            } else if ( cmp == 0 ) {
                return mid;
            } else {
                lo = mid + 1;
            }
        } while (lo < hi);
    }
    return NSNotFound;
}

- (off_t)packOffsetForSha1:(NSString*)sha1
{
    return [self packOffsetForSha1:sha1 error:NULL];
}

- (off_t)packOffsetForSha1:(NSString*)sha1 error:(NSError**)error;
{
    NSUInteger i = [self indexOfSha1:sha1];
    if ( i != NSNotFound )
        return [self packOffsetWithIndex:i];
    // If its found the SHA1 then it will have returned by now.
    // Otherwise the SHA1 is not in this PACK file, so we should
    // raise an error.
    NSString * errorFormat = NSLocalizedString(@"Object %@ is not in index file",@"GITErrorObjectNotFound");
    NSString * errorDesc = [NSString stringWithFormat:errorFormat, sha1];    
    GITError(error, GITErrorObjectNotFound, errorDesc);
    return NSNotFound;
}

- (off_t)baseOffsetWithOffset:(off_t)offset;
{
    return (off_t)[[self revIndex] baseOffsetWithOffset:offset];
}

- (off_t)nextOffsetWithOffset:(off_t)offset;
{
    return (off_t)[[self revIndex] nextOffsetWithOffset:offset];
}

- (NSData*)packChecksum
{
    return [self.data subdataWithRange:[self rangeOfPackChecksum]];
}
- (NSData*)checksum
{
    return [self.data subdataWithRange:[self rangeOfChecksum]];
}
- (BOOL)verifyChecksum
{
    NSData * checkData = [[self.data subdataWithRange:NSMakeRange(0, [self.data length] - 20)] sha1Digest];
    return [checkData isEqualToData:[self checksum]];
}
- (NSRange)rangeOfSignature
{
    return kGITPackIndexSignature;
}
- (NSRange)rangeOfVersion
{
    return kGITPackIndexVersion;
}
- (NSRange)rangeOfFanoutTable
{
    return kGITPackIndexFanout;
}
- (NSRange)rangeOfSHATable
{
    NSUInteger endOfFanout = [self rangeOfFanoutTable].location + [self rangeOfFanoutTable].length;
    return NSMakeRange(endOfFanout, kGITPackIndexSHASize * [self numberOfObjects]);
}
- (NSRange)rangeOfCRCTable
{
    NSUInteger endOfSHATable = [self rangeOfSHATable].location + [self rangeOfSHATable].length;
    return NSMakeRange(endOfSHATable, kGITPackIndexCRCSize * [self numberOfObjects]);
}
- (NSRange)rangeOfOffsetTable
{
    NSUInteger endOfCRCTable = [self rangeOfCRCTable].location + [self rangeOfCRCTable].length;
    return NSMakeRange(endOfCRCTable, kGITPackIndexOffsetSize * [self numberOfObjects]);
}
- (NSRange)rangeOfExtendedOffsetTable
{
    NSUInteger endOfOffsetTable = [self rangeOfOffsetTable].location + [self rangeOfOffsetTable].length;
    return NSMakeRange(endOfOffsetTable, ([self.data length] - endOfOffsetTable - 40));
}
- (NSRange)rangeOfPackChecksum
{
    return NSMakeRange([self.data length] - 40, 20);
}
- (NSRange)rangeOfChecksum
{
    return NSMakeRange([self.data length] - 20, 20);
}

- (NSData *)packedSha1WithIndex:(NSUInteger)i;
{
    NSRange shaRange = [self rangeOfSHATable];
    NSUInteger positionFromStart = i * kGITPackIndexSHASize;
    
    if (positionFromStart < shaRange.length)
    {
        return [self.data subdataWithRange:NSMakeRange(shaRange.location + positionFromStart, kGITPackIndexSHASize)];
    }
    return nil;
}

- (NSString *)sha1WithOffset:(off_t)offset;
{
    NSUInteger index = [[self revIndex] indexWithOffset:offset];
    return unpackSHA1FromData([self packedSha1WithIndex:index]);
}

- (off_t)packOffsetWithIndex:(NSUInteger)i;
{
    NSRange offsetsRange = [self rangeOfOffsetTable];
    NSUInteger positionFromStart = i * kGITPackIndexOffsetSize;
    
    if (positionFromStart >= offsetsRange.length) {
        // Raise index out of bounds exception
        [NSException raise:NSRangeException
                    format:@"pack entry index %u (offset:%lu) out of bounds (%@)",
         i, positionFromStart, NSStringFromRange(offsetsRange)];
    }

    uint32_t value;
    [self.data getBytes:&value range:NSMakeRange(offsetsRange.location + positionFromStart, kGITPackIndexOffsetSize)];

    value = CFSwapInt32BigToHost(value);
    if ((value & EXTENDED_OFFSET_FLAG) == 0)
        return (off_t)value;

    uint32_t off64 = (value & ~EXTENDED_OFFSET_FLAG) * kGITPackIndexExtendedOffsetSize;
    uint64_t v64;
    NSRange extendedOffsetRange = [self rangeOfExtendedOffsetTable];
    [self.data getBytes:&v64 range:NSMakeRange(extendedOffsetRange.location+off64, kGITPackIndexExtendedOffsetSize)];
    return (off_t)CFSwapInt64BigToHost(v64);
}

@end
