//
//  GITRef.m
//  CocoaGit
//
//  Created by Brian Chapados on 2/10/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//

#import "GITRef.h"
#import "GITUtilityBelt.h"

@implementation GITRef
@synthesize name;
@synthesize sha1;
@synthesize alias;

- (BOOL) isAlias { return (alias == nil); }

- (id) init { return nil; }

// designated initializer
- (id) initWithName:(NSString *)refName sha1:(NSString *)sha1String alias:(NSString *)refAlias;
{
    if (! [super init])
        return nil;
    
    [self setName:refName];
    [self setSha1:sha1String];
    [self setAlias:refAlias];
    
    return self;
}

- (void) dealloc;
{
    [name release], name = nil;
    [sha1 release], sha1 = nil;
    [alias release], alias = nil;
    [super dealloc];
}

// convenience initializers - return autoreleased objects
+ (id) refWithName:(NSString *)refName sha1:(NSString *)sha1String;
{
    return [[[self alloc] initWithName:refName sha1:sha1String alias:nil] autorelease];
}

+ (id) refWithName:(NSString *)refName alias:(NSString *)refAlias;
{
    return [[[self alloc] initWithName:refName sha1:nil alias:refAlias] autorelease];
}

+ (id) refWithContentsOfFile:(NSString *)aPath;
{
    NSString *contents = [NSString stringWithContentsOfFile:aPath];
    if (! contents)
        return nil;
    
    NSString *trimmed = [contents stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    if (! isSha1StringValid(trimmed)) {
        return [[[self alloc] initWithName:aPath sha1:nil alias:trimmed] autorelease];
    }
    
    return [[[self alloc] initWithName:aPath sha1:trimmed alias:nil] autorelease];
}

+ (id) refWithPacketLine:(NSString *)packetLine;
{
    NSString *refName, *refSha1;
    NSScanner *scanner = [NSScanner scannerWithString:packetLine];
    [scanner scanUpToString:@" " intoString:&refSha1];
    [scanner scanUpToString:@"\n" intoString:&refName];
    
    if (! (refName && refSha1))
        return nil;
    
    return [[[self alloc] initWithName:refName sha1:refSha1 alias:nil] autorelease];
}
@end
