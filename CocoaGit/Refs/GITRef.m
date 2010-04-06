//
//  GITRef.m
//  CocoaGit
//
//  Created by Brian Chapados on 2/10/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//

#import "GITRef.h"
#import "GITRefStore.h"
#import "GITUtilityBelt.h"
#import "NSFileManager+DirHelper.h"

@interface GITRef()
- (BOOL) isResolved;
- (BOOL) resolveWithStore:(GITRefStore *)store error:(NSError **)error;
@end


@implementation GITRef
@synthesize name;
@synthesize linkName;
@synthesize sha1;
@synthesize isLink;
@synthesize isPacked;

+ (id) refWithName:(NSString *)refName sha1:(NSString *)sha1String;
{
    return [[[self alloc] initWithName:refName sha1:sha1String packed:NO] autorelease];
}

+ (id) refWithName:(NSString *)refName sha1:(NSString *)sha1String packed:(BOOL)refIsPacked;
{
    return [[[self alloc] initWithName:refName sha1:sha1String packed:refIsPacked] autorelease];
}

- (id) initWithName:(NSString *)refName sha1:(NSString *)refSha1;
{
    return [self initWithName:refName sha1:refSha1 packed:NO];
}

- (id) initWithName:(NSString *)refName sha1:(NSString *)refSha1 packed:(BOOL)refIsPacked;
{
    NSString *refLink = nil;
    if ( [refSha1 hasPrefix:@"ref: "] ) {
        refLink = refSha1;
        refSha1 = nil;
    }
    return [self initWithName:refName sha1:refSha1 linkName:refLink packed:refIsPacked];
}

- (id) initWithName:(NSString *)refName sha1:(NSString *)refSha1 
           linkName:(NSString *)refLink packed:(BOOL)refIsPacked;
{
    if (! [super init])
        return nil;
    
    if ( refLink ) {
        [self setLinkName:[refLink substringFromIndex:5]];
        isLink = YES;
    }
    
    if ( !(isLink || isSha1StringValid(refSha1)) ) {
        [self release];
        return nil;
    }
    
    [self setSha1:refSha1];
    [self setName:refName];
    [self setIsPacked:refIsPacked];
    return self;
}

- (void) dealloc;
{
    [name release];
    [sha1 release];
    [linkName release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone*)zone
{
    id obj = [[[self class] allocWithZone:zone] initWithName:[self name] sha1:[self sha1]
                            linkName:[self linkName] packed:[self isPacked]];
    [obj setLinkName:[self linkName]];
    [obj setIsLink:[self isLink]];
    return obj;
}

- (BOOL) resolveWithStore:(GITRefStore *)store error:(NSError **)error
{
    if ( [self isLink] && [self isResolved] )
        return YES;
    NSString *refSha1 = [store sha1WithSymbolicRef:self];
    if ( !isSha1StringValid(refSha1) )
        return NO;
    [self setSha1:refSha1];
    return YES;
}

- (BOOL) isResolved
{
    return isSha1StringValid([self sha1]);
}

- (NSString *) shortName
{
    if ( ![[self name] hasPrefix:@"refs/"] )
        return [self name];
    NSArray *chunks = [[self name] componentsSeparatedByString:@"/"];
    return [[chunks subarrayWithRange:NSMakeRange(2, [chunks count] - 2)]
            componentsJoinedByString:@"/"];
}

// convenience initializers - return autoreleased objects
+ (id) refWithContentsOfFile:(NSString *)aPath
{
    NSRange nameRange = [aPath rangeOfString:@"/refs/"];
    NSString *refName;
    if ( nameRange.location == NSNotFound ) {
        refName = [aPath lastPathComponent];
    } else {
        refName = [aPath substringFromIndex:(nameRange.location + 1)];
    }
    return [self refWithContentsOfFile:aPath name:refName];
}

+ (id) refWithContentsOfFile:(NSString *)aPath name:(NSString *)refName
{
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:aPath] )
        return nil;
    
    NSString *contents = [NSString stringWithContentsOfFile:aPath];
    if (! contents)
        return nil;
    
    NSString *trimmed = [contents stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return [self refWithName:refName sha1:trimmed];
}

+ (id) refWithPacketLine:(NSString *)packetLine;
{
    NSString *refName, *refSha1;
    NSScanner *scanner = [NSScanner scannerWithString:packetLine];
    [scanner scanUpToString:@" " intoString:&refSha1];
    [scanner scanUpToString:@"\n" intoString:&refName];
    
    if (! (refName && refSha1))
        return nil;
    return [self refWithName:refName sha1:refSha1];
}

- (GITCommit *) commitWithRepo:(GITRepo *)repo;
{
    return [repo commitWithSha1:[self sha1] error:NULL];
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@:%x name:%@\n"
                                      @"       sha1:%@\n"
                                      @"   linkName:%@\n"
                                      @"    packed?:%@>",
            [self className], self, [self name],
            [self sha1], [self linkName], ([self isPacked] ? @"YES" : @"NO")];
}
@end