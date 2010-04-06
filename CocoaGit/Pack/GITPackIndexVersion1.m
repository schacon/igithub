//
//  GITPackIndexVersion1.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 04/11/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITPackIndexVersion1.h"
#import "GITPackReverseIndex.h"
#import "GITUtilityBelt.h"
#import "NSData+Hashing.h"
#import "GITErrors.h"

static const NSUInteger kGITPackIndexFanOutSize  = 4;          //!< bytes
static const NSUInteger kGITPackIndexFanOutCount = 256;
static const NSUInteger kGITPackIndexFanOutEnd   = 4 * 256;    //!< Update when either of the two above change
static const NSUInteger kGITPackIndexEntrySize   = 24;         //!< bytes
static const NSUInteger kGITPackIndexSHASize            = 20;
static const NSUInteger kGITPackIndexOffsetSize         = 4;

typedef struct packIndexEntry {
    uint32_t offset;
    uint8_t sha1[20];
} packIndexEntry;

/*! \cond */
@interface GITPackIndexVersion1 ()
- (NSArray*)loadOffsetsWithError:(NSError**)error;
- (NSRange)rangeOfPackChecksum;
- (NSRange)rangeOfChecksum;
- (packIndexEntry *) packEntryWithIndex:(NSUInteger)i;
@end
/*! \endcond */

@implementation GITPackIndexVersion1
@synthesize path;
@synthesize data;
- (id)initWithPath:(NSString*)thePath error:(NSError**)outError
{
    if (self = [super init])
    {
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

- (GITPackReverseIndex *)revIndex;
{
    if (! revIndex) {
        revIndex = [[GITPackReverseIndex alloc] initWithPackIndex:self];
    }
    return revIndex;
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
    return 1;
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
    for (i = 0; i < kGITPackIndexFanOutCount; i++)
    {
        [self.data getBytes:&value range:NSMakeRange(i * kGITPackIndexFanOutSize, kGITPackIndexFanOutSize)];
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
    return _offsets;
}

- (NSUInteger) indexOfSha1:(NSString *)sha1;
{
    const uint8_t *packedSha1 = [(NSData *)packSHA1(sha1) bytes];
    const uint8_t *sha1Data = [[self data] bytes]; 
    
    NSRange rangeOfShas = [self rangeOfObjectsWithFirstByte:packedSha1[0]];
    if (rangeOfShas.length > 0)
    {
        NSUInteger lo = rangeOfShas.location;
        NSUInteger hi = lo + rangeOfShas.length;
        NSUInteger location = kGITPackIndexFanOutEnd;
        do {
            NSUInteger mid = (lo + hi) >> 1; // divide by 2 ;)
            NSUInteger position = (mid * kGITPackIndexEntrySize) + location + kGITPackIndexOffsetSize;
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

- (off_t) packOffsetForSha1:(NSString*)sha1
{
    return [self packOffsetForSha1:sha1 error:NULL];
}

- (off_t) packOffsetForSha1:(NSString*)sha1 error:(NSError**)error
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

- (NSData *)packedSha1WithIndex:(NSUInteger)i;
{
    packIndexEntry *entry = [self packEntryWithIndex:i];
    NSData *packedSha1 = [NSData dataWithBytes:(const uint8_t *)entry->sha1 length:20];
    return packedSha1;
}

- (NSString *)sha1WithOffset:(off_t)offset;
{
    NSUInteger index = [[self revIndex] indexWithOffset:offset];
    return unpackSHA1FromData([self packedSha1WithIndex:index]);
}

- (off_t) packOffsetWithIndex:(NSUInteger)i;
{
    packIndexEntry *entry = [self packEntryWithIndex:i];
    off_t offset = CFSwapInt32BigToHost(entry->offset);
    return offset;
}

- (packIndexEntry *) packEntryWithIndex:(NSUInteger)i;
{
    NSRange offsetsRange = NSMakeRange(kGITPackIndexFanOutEnd,
                                       [self rangeOfPackChecksum].location - kGITPackIndexFanOutEnd);    
    NSUInteger positionFromStart = i * kGITPackIndexEntrySize;
    if (positionFromStart >= offsetsRange.length) {
        // Raise index out of bounds exception
        [NSException raise:NSRangeException
                    format:@"pack entry index %u (offset:%lu) out of bounds (%@)",
                            i, positionFromStart, NSStringFromRange(offsetsRange)];
    }    
    packIndexEntry entry, *e = &entry;

    [self.data getBytes:e
     range:NSMakeRange(offsetsRange.location + positionFromStart, kGITPackIndexEntrySize)];
    return e;
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
- (NSRange)rangeOfPackChecksum
{
    return NSMakeRange([self.data length] - 40, 20);
}
- (NSRange)rangeOfChecksum
{
    return NSMakeRange([self.data length] - 20, 20);
}
@end
