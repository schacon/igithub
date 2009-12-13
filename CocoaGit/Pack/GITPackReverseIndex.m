//
//  GITPackReverseIndex.m
//  CocoaGit
//
//  Created by Brian Chapados on 2/16/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//
#import "GITPackReverseIndex.h"
#import "GITPackIndex.h"

@interface GITPackReverseIndex ()
@property (nonatomic, assign) GITPackIndex *index;
- (BOOL) buildReverseIndex;
@end

@implementation GITPackReverseIndex
@synthesize index;

+ (id) reverseIndexWithIndex:(GITPackIndex *)packIndex;
{
    return [[[self alloc] initWithPackIndex:packIndex] autorelease];
}

- (id) initWithPackIndex:(GITPackIndex *) packIndex;
{
    if (! [super init])
        return nil;
    
    [self setIndex:packIndex];
    
    if (! [self buildReverseIndex]) {
        [self release];
        return nil;
    }
    
    return self;
}

- (void) dealloc;
{
    CFRelease(offsets), offsets = nil;
    index = nil;
    size = 0;
    [super dealloc];
}

struct revIdx {
    off_t offset;
    NSUInteger idx;
};
typedef struct revIdx revIdx;

static int compareOffset(const void *a, const void *b)
{
    const struct revIdx *u = a;
    const struct revIdx *v = b;
    return ( u->offset < v->offset ) ? -1 : ( u->offset > v->offset ) ? 1 : 0;
}

CFComparisonResult CFCompareOffset(const void *a, const void *b, void *context)
{
    return (CFComparisonResult)compareOffset(a, b);
}

const void *revIdxRetain(CFAllocatorRef allocator, const void *ptr)
{
    const revIdx *p = ptr;
    revIdx *new = (revIdx *)CFAllocatorAllocate(allocator, sizeof(revIdx), 0);
    new->offset = p->offset;
    new->idx = p->idx;
    return new;
}

void revIdxRelease(CFAllocatorRef allocator, const void *ptr) {
    CFAllocatorDeallocate(allocator, (revIdx *)ptr);
}

static Boolean offsetsEqual(const void *a, const void *b)
{
    const struct revIdx *u = a;
    const struct revIdx *v = b;
    return ((off_t)u->offset == (off_t)v->offset);
}


- (BOOL) buildReverseIndex;
{
    NSUInteger objectCount = [[self index] numberOfObjects];
    size = objectCount;
    
    CFArrayCallBacks offsetCallbacks = { 0, revIdxRetain, revIdxRelease, NULL, offsetsEqual };
    CFMutableArrayRef off32 = CFArrayCreateMutable(kCFAllocatorDefault, objectCount, &offsetCallbacks);

    NSUInteger i;
    for(i = 0; i < objectCount; i++) {
        off_t packOffset = [index packOffsetWithIndex:i];
        revIdx entry;
        entry.offset = packOffset;
        entry.idx = i;
        CFArrayAppendValue(off32, &entry);
    }
        
    CFArraySortValues(off32, CFRangeMake(0, objectCount), CFCompareOffset, NULL);
    offsets = off32;
    
    return YES;
}

- (NSUInteger) indexOfOffset:(off_t)offset
{
    revIdx search;
    search.offset = offset;
    search.idx = 0;
    NSUInteger result = (NSUInteger)CFArrayBSearchValues(offsets, CFRangeMake(0, size), &search, CFCompareOffset, NULL);
    if ( !CFArrayContainsValue(offsets, CFRangeMake(result, 1), &search) )
        return NSNotFound;
    return result;
}

- (NSUInteger) indexWithOffset:(off_t)offset
{
    revIdx search;
    search.offset = offset;
    search.idx = 0;
    NSUInteger result = (NSUInteger)CFArrayBSearchValues(offsets, CFRangeMake(0, size), &search, CFCompareOffset, NULL);
    if ( !CFArrayContainsValue(offsets, CFRangeMake(result, 1), &search) )
        return NSNotFound;
    revIdx *idx = (revIdx*)CFArrayGetValueAtIndex(offsets, result);
    return idx->idx;
}

// return the next offset after object at offset: thisOffset
//   return NSNotFound if thisOffset isn't found
//   return -1 if thisOffset is the last offset
- (off_t) nextOffsetWithOffset:(off_t)thisOffset;
{
    revIdx search = { thisOffset, 0 };
    NSUInteger i = (NSUInteger)CFArrayBSearchValues(offsets, CFRangeMake(0, size), &search, CFCompareOffset, NULL);
    if ( i == NSNotFound )
        return NSNotFound;
    if ( i+1 == size )
        return -1;
    revIdx *result = (revIdx*)CFArrayGetValueAtIndex(offsets, i+1);
    return (off_t)result->offset;
}

// return the start offset of the object containing for current offset
//  return offsetOfLastObject if 'theOffset' > offsetOfLastObject
//  return offsetOfFirstObject if 'theOffset' < offsetOfFirstObject
- (off_t) baseOffsetWithOffset:(off_t)theOffset;
{
    revIdx search = { theOffset, 0 };
    NSUInteger i = (NSUInteger)CFArrayBSearchValues(offsets, CFRangeMake(0, size), &search, CFCompareOffset, NULL);
    if ( i == NSNotFound || i >= size ) {
        i = size - 1;
    } else {
        if ( i > 0 ) i--;
    }
    revIdx *result = (revIdx*)CFArrayGetValueAtIndex(offsets, i);
    return (off_t)result->offset;
}
@end